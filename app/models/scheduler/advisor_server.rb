require 'drb/drb'

module Scheduler
  class AdvisorServer
    include Singleton

    def self.start
      DRb.start_service SchedulerAdvisor.uri, instance, safe_level: 1
    end
  
    def method_missing(name, *args)
      Rails.logger.warn "Received unknown command #{name} with arguments #{args}"
    end

    def quit
      Rails.logger.info "Quitting per advisor request"
      EM.stop
    end

    def mission_started(mission_id)
      mission = Mission.where(id: mission_id).first
      unless mission.nil?
        organization_id = mission.organization_id
        Rails.logger.debug "Organization ##{organization_id}: Mission #{mission.name} was started"
        EM.schedule do
          Scheduler.organization(organization_id).schedule_mission_check(mission.id)
        end
      end
    end

    def channel_enabled(channel_id)
      channel = PigeonChannel.where(id: channel_id).first
      unless channel.nil?
        organization_id = channel.organization_id
        Rails.logger.debug "Organization ##{organization_id}: Channel #{channel.name} was enabled"
        EM.schedule do
          Scheduler.organization(organization_id).schedule_janitor
        end
      end
    end

    def candidate_status_updated(candidate_id)
      candidate = Candidate.where(id: candidate_id).first
      unless candidate.nil?
        mission = candidate.mission
        organization_id = mission.organization_id
        Rails.logger.debug "Organization ##{organization_id}: Candidate #{candidate.volunteer.name} status updated"
        EM.schedule do
          Scheduler.organization(organization_id).schedule_mission_check(mission.id)
        end
      end
    end

    def call_status_update(session_id, call_status)
      Rails.logger.debug "Call status update for call #{session_id} with status #{call_status}"
      EM.schedule do
        Scheduler.call_status_update session_id, call_status
      end
    end
  end
end

