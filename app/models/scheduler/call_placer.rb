class Scheduler::CallPlacer
  def initialize(scheduler)
    @scheduler = scheduler
    @organization = scheduler.organization
  end

  def max_voice_retries
    @max_voice_retries ||= @organization.max_voice_retries
  end

  def voice_timeout
    @voice_timeout ||= @organization.voice_timeout.minutes
  end

  def missions_by_latest_voice_attempt
    @organization.missions.where(:status => :running).
      joins(:candidates).
      select("MAX(candidates.last_voice_att) as latest_voice_att, missions.id").
      group("missions.id").
      order('latest_voice_att')
  end

  def find_next_volunteer_to_call
    missions = missions_by_latest_voice_attempt.to_a
    candidate = nil
    missions.find do |mission|
      pending_allocations = mission.pending_allocation_by_risk
      volunteers = pending_allocations.map(&:second).flatten

      # volunteers now contains a list of people to call
      # filter out those that don't have voice numbers
      volunteers = volunteers.select { |v| v.has_voice? }

      # map to candidates for the mission
      candidate_map = mission.pending_candidates.inject({}) do |accum, c|
        accum[c.volunteer.id] = c
        accum
      end
      candidates = volunteers.map { |v| candidate_map[v.id] }

      # find the first candidate that has retries left and his timeout has
      # expired (after we tried all his voice numbers)
      candidate = candidates.find do |c|
        c.active? && c.has_voice_retries? && 
          (c.last_voice_att.nil? || 
           c.last_voice_att <= voice_timeout.ago || 
           !c.volunteer.is_last_voice_number?(c.last_voice_number))
      end
    end
    candidate
  end

  def status_callback_url
    Rails.application.routes.url_helpers.verboice_status_callback_url
  end

  def place_call(candidate, channel)
    number = candidate.next_number_to_call

    Rails.logger.debug "Calling #{candidate.volunteer.name} at #{number} for mission #{candidate.mission.name} through #{channel.name}"

    begin
      verboice = Verboice.from_config
      response = verboice.call number, 
        :channel => channel.pigeon_name, 
        :status_callback_url => status_callback_url

      call = candidate.current_calls.build 
      call.pigeon_channel = channel
      call.voice_number = number
      call.call_status = response['state']
      call.session_id = response['call_id']
      call.save!

    rescue Exception => e
      Rails.logger.error "Error calling candidate #{candidate.id}, exception: #{e}"
      response = { 'call_id' => nil, 'state' => 'failed' }
    end

    candidate.last_voice_number = number
    candidate.last_call_status = response['state']
    candidate.last_voice_att = Time.now.utc
    if candidate.volunteer.is_last_voice_number?(number)
      candidate.voice_retries += 1 
    end
    candidate.save :validate => false

    call
  end

  def perform
    return unless @scheduler.call_slots_available?

    channel = @scheduler.next_voice_channel
    return if channel.nil?

    candidate = find_next_volunteer_to_call
    place_call(candidate, channel) unless candidate.nil?
  end

  def next_deadline
    return nil unless @scheduler.has_voice_channels?

    # get the time at which we should perform a new SMS send
    older = Candidate.
      where(:status => :pending, :active => true).
      joins(:mission).
      where("missions.organization_id = ?", @organization.id).
      where("missions.status = ?", :running).
      joins(:volunteer => [:voice_channels]).
      where("voice_retries < ?", max_voice_retries).
      order("last_voice_att ASC").first
    if older
      if older.last_voice_att.nil?
        Time.now
      elsif !older.volunteer.is_last_voice_number?(older.last_voice_number)
        older.last_voice_att
      else
        older.last_voice_att + voice_timeout
      end
    else
      nil
    end
  end
end

