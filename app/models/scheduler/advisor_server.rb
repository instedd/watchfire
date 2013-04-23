module Scheduler::AdvisorServer
  include EventMachine::Protocols::LineProtocol

  def receive_line(line)
    tokens = JSON.parse(line)
    Rails.logger.debug "Received #{tokens[0]} command with #{tokens[1..-1]}"

    case tokens[0]
    when 'quit'
      Rails.logger.info "Quitting per advisor request"
      EM.stop

    when 'mission_started'
      mission_id = tokens[1]
      mission = Mission.where(id: mission_id).first
      unless mission.nil?
        organization_id = mission.organization_id
        Rails.logger.debug "Organization ##{organization_id}: Mission #{mission.name} was started"
        Scheduler.organization(organization_id).schedule_mission_check(mission.id)
      end

    when 'channel_enabled'
      channel_id = tokens[1]
      channel = PigeonChannel.where(id: channel_id).first
      unless channel.nil?
        organization_id = channel.organization_id
        Rails.logger.debug "Organization ##{organization_id}: Channel #{channel.name} was enabled"
        Scheduler.organization(organization_id).schedule_janitor
      end

    when 'candidate_status_updated'
      candidate_id = tokens[1]
      candidate = Candidate.where(id: candidate_id).first
      unless candidate.nil?
        mission = candidate.mission
        organization_id = mission.organization_id
        Rails.logger.debug "Organization ##{organization_id}: Candidate #{candidate.volunteer.name} status updated"
        Scheduler.organization(organization_id).schedule_mission_check(mission.id)
      end

    end
  end
end

