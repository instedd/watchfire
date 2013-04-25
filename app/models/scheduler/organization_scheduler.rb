class Scheduler::OrganizationScheduler
  JANITOR_INTERVAL = 60*10

  attr_reader :organization

  def initialize(organization)
    @organization = organization
  end

  def start
    puts "Starting scheduler for #{organization.name}"
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

  def has_sms_channels?
    organization.pigeon_channels.nuntium.enabled.any?
  end

  def has_voice_channels?
    organization.pigeon_channels.verboice.enabled.any?
    # FIXME
    false
  end

  def has_channels?
    organization.pigeon_channels.enabled.any?
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


  def janitor
    organization.reload
    puts "Periodic job for #{organization.name}"

    active_missions.each do |mission|
      puts "Scheduling mission check for #{mission.name}"
      timers = missions[mission.id]
      schedule_mission_check(mission.id)
    end
  end


  def mission_check(mission_id)
    mission = organization.missions.where(id: mission_id).first
    return if mission.nil? || !mission.is_running?

    puts "Mission check for #{mission.name}"

    mission.check_for_more_volunteers

    schedule_next_sms_send(mission) if has_sms_channels?
    schedule_next_unresponsive_sweep(mission)
  end

  def schedule_next_sms_send(mission)
    timers = missions[mission.id]
    EM.cancel_timer(timers[:sms]) unless timers[:sms].nil?
    
    sms_sender = Scheduler::SmsSender.new(mission, self)
    next_sms_deadline = sms_sender.next_deadline
    if next_sms_deadline
      if next_sms_deadline.past?
        puts "Will send SMS next for #{mission.name}"
      else
        puts "Will send SMS again at #{next_sms_deadline} for #{mission.name}"
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
    mission = organization.missions.where(id: mission_id).first
    return if mission.nil? || !mission.is_running?

    puts "Sending SMSs for #{mission.name}"

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
        puts "Will mark unresponsive candidates next for #{mission.name}"
      else
        puts "Will mark unresponsive candidates at #{next_sweep_deadline} for #{mission.name}"
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
    mission = organization.missions.where(id: mission_id).first
    return if mission.nil? || !mission.is_running?

    puts "Marking unresponsive candidates for #{mission.name}"

    sweeper = Scheduler::UnresponsiveSweeper.new(mission, self)
    if sweeper.perform
      schedule_mission_check mission_id
    end
  end
end

