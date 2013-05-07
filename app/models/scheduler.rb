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

    def call_status_update(session_id, call_status)
      call = CurrentCall.find_by_session_id(session_id)
      unless call.nil?
        org = call.candidate.mission.organization
        organization(org.id).call_status_update(session_id, call_status)
      else
        Rails.logger.warn "Received call status update for unknown call #{session_id}"
      end
    end

  private

    def start_organization(org)
      Scheduler::OrganizationScheduler.new(org).tap { |sched|
        sched.start
      }
    end
  end
end

