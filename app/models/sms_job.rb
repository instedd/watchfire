class SmsJob < CandidateJob
  def perform
    candidate = Candidate.find(candidate_id)
    
    # if candidate is not pending then stop sending sms
    return if candidate.is_not_pending?
    
    # check if candidate has run out of sms retries
    unless candidate.has_sms_retries?
      candidate.update_status :unresponsive unless candidate.has_retries?
      return
    end
    
    # Send SMS
    nuntium = Nuntium.from_config
		begin
			message = {
	      :from => "sms://watchfire",
	      :to => candidate.volunteer.sms_number.with_protocol,
	      :body => candidate.mission.sms_message
	    }
	    nuntium.send_ao message
		rescue Nuntium::Exception => e
			
		ensure
			# Increase retries and set last sms attempt timestamp
			candidate.sms_retries = candidate.sms_retries + 1
      candidate.last_sms_att = Time.now.utc
      candidate.save :validate => false
		end
    
    # Enqueue new job with time = sms timeout
    Delayed::Job.enqueue SmsJob.new(candidate_id), :run_at => config.sms_timeout.minutes.from_now
  end
end