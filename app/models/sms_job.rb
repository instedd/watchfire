class SmsJob < Struct.new(:candidate_id)
  def perform
    config = Watchfire::Application.config
    candidate = Candidate.find(candidate_id)
    
    # if candidate is not pending then stop sending sms
    return if candidate.is_not_pending?
    
    # check if candidate has run out of retries
    unless candidate.has_retries?
      candidate.update_status :unresponsive
      return
    end
    
    # Send SMS
    api = Nuntium.new config.nuntium_host, config.nuntium_account, config.nuntium_app, config.nuntium_app_passwd
    
    message = {
      :from => "sms://0",
      :to => "sms://#{candidate.volunteer.sms_number}",
      :body => "You are needed for an emergency. Reply 1 for Yes, 2 for No",
    }
    
    response = api.send_ao message
    
    # if the request is successful, increase retries and set last sms attempt timestamp
    if response.code == 200
      candidate.sms_retries = candidate.sms_retries + 1
      candidate.last_sms_att = Time.now.utc
      candidate.save :validate => false
    end
    
    # Enqueue new job with time = sms timeout
    Delayed::Job.enqueue SmsJob.new(candidate_id), :run_at => config.sms_timeout.minutes.from_now
  end
end