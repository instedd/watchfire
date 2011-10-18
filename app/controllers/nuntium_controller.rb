class NuntiumController < BasicAuthController
  
  def receive
    begin
      config = Watchfire::Application.config
      from = params[:from]
      body = params[:body]
      
      # parse fields
      number_match = from.match /sms:\/\/(\d+)/
      response_match = body.downcase.match /^(yes|no)$/
    
      raise 'Error parsing number' unless number_match
      
      unless response_match
        message = I18n.t :sms_bad_format, :text => body
        raise 'Error parsing response' 
      end
    
      number = number_match[1]
      confirmation = response_match[1] == 'yes'
      
      # find matching candidate for the given number
      candidate = Candidate.find_last_for_sms_number number
      
      # check if candidate is unresponsive
      if candidate.is_unresponsive?
        raise 'Error candidate is unresponsive'
      end
    
      # update status based on response
      if confirmation
        candidate.update_status :confirmed
      else
        candidate.update_status :denied
      end
      
      message = I18n.t :sms_successful
    rescue => e
      logger.error e
    end
    
    render :text => message, :content_type => "text/plain"
  end
  
end
