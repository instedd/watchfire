class Scheduler::OrganizationScheduler
  attr_accessor :organization

  def initialize(organization)
    @organization = organization
  end

  def has_channels?
    organization.pigeon_channels.enabled.any?
  end

  def start
    if has_channels?
      puts "Starting scheduler for #{organization.name}"
      schedule_next
      self
    else
      nil
    end
  end

  def schedule_next
    EM.add_timer 5, self
  end

  def call
    puts "Periodic job for #{organization.name}"
    schedule_next
  end
end

