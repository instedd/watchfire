class Scheduler::OrganizationScheduler
  JANITOR_INTERVAL = 10

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

private

  def missions
    @mission ||= Hash.new do |hash, id|
      hash[id] = { check: nil }
    end
  end

  def has_channels?
    organization.pigeon_channels.enabled.any?
  end

  def active_missions
    organization.missions.where(:status => :running)
  end


  def janitor
    organization.reload
    puts "Periodic job for #{organization.name}"

    active_missions.each do |mission|
      puts "Scheduling mission check for #{mission.name}"
      schedule_mission_check(mission.id)
    end
  end


  def mission_check(mission_id)
    mission = organization.missions.where(id: mission_id).first
    return if mission.nil? || !mission.is_running?

    puts "Mission check for #{mission.name}"

  end

end

