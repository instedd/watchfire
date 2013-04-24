require 'eventmachine'

module Scheduler
  class << self
    def organizations
      @organizations ||= Hash.new do |hash, key|
        org = Organization.find(key)
        hash[key] = start_organization(org)
      end
    end

    def start
      Scheduler::AdvisorServer.start

      Organization.all.each do |org|
        organizations[org.id] = start_organization(org)
      end
    end

    def organization(id)
      organizations[id]
    end

  private

    def start_organization(org)
      Scheduler::OrganizationScheduler.new(org).tap { |sched|
        sched.start
      }
    end
  end
end

