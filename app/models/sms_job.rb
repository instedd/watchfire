class SmsJob < CandidateJob
	def perform
		JobLogger.debug "SmsJob: Executing for Candidate #{candidate_id}"
		candidate = Candidate.find(candidate_id)
		
		# if candidate is not pending then stop sending sms
		if candidate.is_not_pending?
			JobLogger.debug "SmsJob: Candidate #{candidate_id} is not pending, quitting job"
			return
		end
		
		# check if candidate has run out of sms retries
		unless candidate.has_sms_retries?
			unless candidate.has_retries?
				JobLogger.debug "SmsJob: Candidate #{candidate_id} has ran out of retries, setting status to unresponsive"
				candidate.no_answer!
			end
			JobLogger.debug "SmsJob: Candidate #{candidate_id} has ran out of sms retries, quitting job"
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
			JobLogger.debug "SmsJob: Sending AO message to Candidate #{candidate_id}, address is #{message[:to]}"
			nuntium.send_ao message
		rescue Nuntium::Exception => e
			JobLogger.error "SmsJob: Error sending AO for Candidate #{candidate_id}, exception: #{e}"
		ensure
			# Increase retries and set last sms attempt timestamp
			candidate.sms_retries = candidate.sms_retries + 1
			candidate.last_sms_att = Time.now.utc
			candidate.save :validate => false
		end
		
		# Enqueue new job with time = sms timeout
		JobLogger.debug "SmsJob: Enqueuing new job for Candidate #{candidate_id}"
		Delayed::Job.enqueue SmsJob.new(candidate_id), :run_at => config.sms_timeout.minutes.from_now
	end
end