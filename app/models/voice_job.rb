class VoiceJob < CandidateJob
  def perform
    JobLogger.debug "VoiceJob: Executing for Candidate #{candidate_id}"
    candidate = Candidate.find(candidate_id)

    # if candidate is not pending then stop calling him
    if candidate.is_not_pending?
      JobLogger.debug "VoiceJob: Candidate #{candidate_id} is not pending, quitting job"
      return
    end

    # check if candidate has run out of voice retries
    unless candidate.has_voice_retries?
      unless candidate.has_retries?
        JobLogger.debug "VoiceJob: Candidate #{candidate_id} has ran out of retries, setting status to unresponsive"
        candidate.no_answer!
      end
      JobLogger.debug "VoiceJob: Candidate #{candidate_id} has ran out of voice retries, quitting job"
      return
    end

    # check if last call has finished and call candidate
    @verboice = Verboice.from_config
    last_call = candidate.last_call

    if last_call
      begin
        response = @verboice.call_state last_call.session_id 
        state = response['state']
        unless state == "active" || state == "queued"
          JobLogger.debug "VoiceJob: Candidate #{candidate_id} last call has finished => call him"
          call candidate, last_call
        else
          JobLogger.debug "VoiceJob: Candidate #{candidate_id} has a pending call in Verboice => do not call him"
        end
      rescue Exception => e
        JobLogger.debug "VoiceJob: Error getting call state for candidate #{candidate_id} => make a new call"
        call candidate, last_call
      end
    else
      JobLogger.debug "VoiceJob: Candidate #{candidate_id} doesn't have any previous call => call him"
      call candidate
    end


    # Enqueue new job with time = voice timeout
    JobLogger.debug "VoiceJob: Enqueuing new job for Candidate #{candidate_id}"
    Delayed::Job.enqueue VoiceJob.new(candidate_id), :run_at => candidate.voice_timeout.minutes.from_now
  end

  private

  def call candidate, last_call = nil
    # get an ordered list of numbers to call
    voice_numbers = candidate.volunteer.voice_channels.sort_by(&:id).map(&:address)
    # and pick either the first, or the next from the one called last
    number_index = 0
    if last_call
      number_index = (voice_numbers.index(last_call.voice_number) || -1) + 1
    end
    voice_number = voice_numbers[number_index % voice_numbers.length]

    begin
      JobLogger.debug "VoiceJob: Calling Candidate #{candidate_id} through Verboice, number is #{candidate.volunteer.voice_channels.first.address}"
      response = @verboice.call voice_number, :status_callback_url => Rails.application.routes.url_helpers.verboice_status_callback_url

      session_id = response['call_id']
      JobLogger.debug "VoiceJob: Adding Call with session_id #{session_id} to Candidate #{candidate_id}"
      candidate.calls.create! :session_id => session_id, :voice_number => voice_number
    rescue Exception => e
      JobLogger.error "VoiceJob: Error calling Candidate #{candidate_id}, exception: #{e}"
    ensure
      # increment retries only if the called number was the last one for the volunteer
      if number_index == voice_numbers.size - 1
        candidate.voice_retries = candidate.voice_retries + 1
      end
      candidate.last_voice_att = Time.now.utc
      candidate.save :validate => false
    end
  end

end
