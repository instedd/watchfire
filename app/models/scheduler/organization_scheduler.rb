class Scheduler::OrganizationScheduler
  JANITOR_INTERVAL = 60*10
  CALL_TIMEOUT = 10.minutes

  attr_reader :organization

  def initialize(organization)
    @organization = organization
  end

  def start
    Rails.logger.info "Starting scheduler for #{organization.name}"
    schedule_janitor
  end

  def schedule_janitor(timeout = 0)
    EM.cancel_timer(@janitor_timer) unless @janitor_timer.nil?
    @janitor_timer = EM.add_timer(timeout) do
      @janitor_timer = nil
      janitor
      schedule_janitor(JANITOR_INTERVAL)
    end
  end

  def schedule_mission_check(id, timeout = 0)
    timers = missions[id]
    EM.cancel_timer(timers[:check]) unless timers[:check].nil?
    timers[:check] = EM.add_timer(timeout) do
      timers[:check] = nil
      mission_check id 
    end
  end

  def schedule_try_call
    return unless call_slots_available?

    EM.cancel_timer(@try_call_timer) unless @try_call_timer.nil?
    @try_call_timer = nil

    call_deadline = Scheduler::CallPlacer.new(self).next_deadline
    return if call_deadline.nil?

    timeout = if call_deadline.past?
                Rails.logger.debug "Scheduling place call next for #{organization.name}"
                0
              else
                Rails.logger.debug "Scheduling place call at #{call_deadline} for #{organization.name}"
                call_deadline - Time.now
              end
    @try_call_timer = EM.add_timer(timeout) do
      @try_call_timer = nil
      try_call
    end
  end

  def try_call
    Scheduler::CallPlacer.new(self).perform
    schedule_try_call
  end

  def sms_channels
    @sms_channels ||= organization.pigeon_channels.nuntium.enabled
  end

  def has_sms_channels?
    sms_channels.any?
  end

  def voice_channels
    @voice_channels ||= organization.pigeon_channels.verboice.enabled
  end

  def has_voice_channels?
    organization.pigeon_channels.verboice.enabled.any?
  end

  def has_channels?
    organization.pigeon_channels.enabled.any?
  end

  def call_slots_available?
    has_voice_channels? && voice_channels.any?(&:has_slots_available?)
  end

  def call_status_update(session_id, call_status)
    call = CurrentCall.find_by_session_id(session_id)
    return if call.nil?

    call.update_status! call_status

    if call.ended?
      call.destroy
      schedule_try_call
      schedule_next_unresponsive_sweep(call.candidate.mission)
    end
  end

  def next_sms_channel
    @last_sms_channel_used = sms_channels.cycle(2).drop_while { |c|
      c != @last_sms_channel_used
    }.second || sms_channels.first
  end

  def next_voice_channel
    voice_channels.find { |c| c.has_slots_available? }
  end

  def free_idle_call_slots
    CurrentCall.where("updated_at < ?", CALL_TIMEOUT.ago).each do |call|
      call.timeout
      call.destroy
    end
  end

  def janitor
    organization.reload
    @sms_channels = nil
    @voice_channels = nil

    Rails.logger.debug "Periodic job for #{organization.name}"

    active_missions.each do |mission|
      Rails.logger.debug "Scheduling mission check for #{mission.name}"
      timers = missions[mission.id]
      schedule_mission_check(mission.id)
    end

    free_idle_call_slots
    schedule_try_call
  end

  def mission_check(mission_id)
    mission = find_active_mission(mission_id)
    return if mission.nil?

    Rails.logger.debug "Mission check for #{mission.name}"

    mission.check_for_more_volunteers

    if mission.is_running?
      schedule_next_sms_send(mission) if has_sms_channels?
      schedule_next_unresponsive_sweep(mission)
      schedule_try_call if call_slots_available?
    end
  end

private

  def missions
    @missions ||= Hash.new do |hash, id|
      hash[id] = { check: nil, sms: nil, sweep: nil }
    end
  end

  def active_missions
    organization.missions.where(:status => :running)
  end

  def find_active_mission(mission_id)
    active_missions.where(id: mission_id).first
  end

  def schedule_next_sms_send(mission)
    timers = missions[mission.id]
    EM.cancel_timer(timers[:sms]) unless timers[:sms].nil?
    
    sms_sender = Scheduler::SmsSender.new(mission, self)
    next_sms_deadline = sms_sender.next_deadline
    if next_sms_deadline
      if next_sms_deadline.past?
        Rails.logger.debug "Will send SMS next for #{mission.name}"
      else
        Rails.logger.debug "Will send SMS again at #{next_sms_deadline} for #{mission.name}"
      end
      timeout = if next_sms_deadline.past? 
                   0
                 else 
                   next_sms_deadline - Time.now 
                 end
      timers[:sms] = EM.add_timer(timeout) do
        timers[:sms] = nil
        send_sms mission.id
      end
    end
  end

  def send_sms(mission_id)
    return unless has_sms_channels?
    mission = find_active_mission(mission_id)
    return if mission.nil?

    Rails.logger.debug "Sending SMSs for #{mission.name}"

    sender = Scheduler::SmsSender.new(mission, self)
    sender.perform

    schedule_next_sms_send mission
    schedule_next_unresponsive_sweep mission
  end

  def schedule_next_unresponsive_sweep(mission)
    timers = missions[mission.id]
    EM.cancel_timer(timers[:sweep]) unless timers[:sweep].nil?
    
    sweeper = Scheduler::UnresponsiveSweeper.new(mission, self)
    next_sweep_deadline = sweeper.next_deadline
    if next_sweep_deadline
      if next_sweep_deadline.past?
        Rails.logger.debug "Will mark unresponsive candidates next for #{mission.name}"
      else
        Rails.logger.debug "Will mark unresponsive candidates at #{next_sweep_deadline} for #{mission.name}"
      end
      timeout = if next_sweep_deadline.past? 
                   0
                 else 
                   next_sweep_deadline - Time.now 
                 end
      timers[:sweep] = EM.add_timer(timeout) do
        timers[:sweep] = nil
        mark_unresponsives mission.id
      end
    end
  end

  def mark_unresponsives(mission_id)
    mission = find_active_mission(mission_id)
    return if mission.nil?

    Rails.logger.debug "Marking unresponsive candidates for #{mission.name}"

    sweeper = Scheduler::UnresponsiveSweeper.new(mission, self)
    if sweeper.perform
      schedule_mission_check mission_id
    end
  end
end

