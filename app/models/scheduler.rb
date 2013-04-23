require 'eventmachine'

class Scheduler
  class << self
    def organizations
      @organizations ||= {} 
    end

    def start
      EM.start_server "127.0.0.1", SchedulerAdvisor.port, AdvisorServer

      Organization.all.each do |organization|
        start_organization(organization)
      end
    end

    def start_organization(organization)
      return if organizations[organization.id].present?

      sched = Scheduler::OrganizationScheduler.new(organization).start
      organizations[organization.id] = sched if sched.present?
    end
  end

  class AdvisorServer < EM::Connection
    include EventMachine::Protocols::LineProtocol

    def receive_line(line)
      tokens = JSON.parse(line)
      case tokens[0]
      when 'quit'
        puts "Quitting per advisor request"
        EM.stop
      else
        puts "Received #{tokens[0]} command with #{tokens[1..-1]}"
      end
    end
  end
end

