class VoiceJob < Struct.new(:candidate_id)
  def perform
    config = Watchfire::Application.config
    candidate = Candidate.find(candidate_id)
    
    # if candidate is not pending then stop calling him
    return if candidate.is_not_pending?
    
    # check if candidate has run out of retries
    if candidate.voice_retries >= config.max_voice_retries
      candidate.status = :unresponsive
      candidate.save :validate => false
      return
    end
    
    # call the candidate
    api = Verboice.new config.verboice_host, config.verboice_account, config.verboice_password, config.verboice_channel
    response = api.call candidate.volunteer.voice_number
    
    # if the request is successful, increase retries,
    # save call_id and set last voice attempt timestamp
    if response.code == 200
      candidate.call_id = response['call_id']
      candidate.voice_retries = candidate.voice_retries + 1
      candidate.last_voice_att = Time.now.utc
      candidate.save :validate => false
    end
    
    # Enqueue new job with time = voice timeout
    Delayed::Job.enqueue VoiceJob.new(candidate_id), :run_at => config.voice_timeout.minutes.from_now
  end
end