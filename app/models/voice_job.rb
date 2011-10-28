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
      response = @verboice.call_state last_call.session_id
      state = response['state']
      unless state == "active" || state == "queued"
        JobLogger.debug "VoiceJob: Candidate #{candidate_id} last call has finished => call him"
        call candidate
      else
        JobLogger.debug "VoiceJob: Candidate #{candidate_id} has a pending call in Verboice => do not call him"
      end
    else
      JobLogger.debug "VoiceJob: Candidate #{candidate_id} doesn't have any previous call => call him"
      call candidate
    end
    
    
    # Enqueue new job with time = voice timeout
    JobLogger.debug "VoiceJob: Enqueuing new job for Candidate #{candidate_id}"
    Delayed::Job.enqueue VoiceJob.new(candidate_id), :run_at => config.voice_timeout.minutes.from_now
  end
  
  private
  
  def call candidate
    begin
      JobLogger.debug "VoiceJob: Calling Candidate #{candidate_id} through Verboice, number is #{candidate.volunteer.voice_number}"
      response = @verboice.call candidate.volunteer.voice_number
      
      session_id = response['call_id']
      JobLogger.debug "VoiceJob: Adding Call with session_id #{session_id} to Candidate #{candidate_id}"
      candidate.calls.create! :session_id => session_id
    rescue Exception => e
      JobLogger.error "VoiceJob: Error calling Candidate #{candidate_id}, exception: #{e}"
    ensure
      candidate.voice_retries = candidate.voice_retries + 1
      candidate.last_voice_att = Time.now.utc
      candidate.save :validate => false
    end
  end
  
end