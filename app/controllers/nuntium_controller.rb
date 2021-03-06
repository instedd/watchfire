class NuntiumController < BasicAuthController
  def receive
    begin
      from = params[:from]
      body = params[:body]

      # Parse fields
      number_match = from.match(/sms:\/\/(\d+)/)
      response_match = body.downcase.match(/(yes|no)/)

      # Check for valid number
      raise 'Error parsing number' unless number_match

      # Check if response is ok
      unless response_match
        message = I18n.t :sms_bad_format, :text => body
        raise 'Error parsing response'
      end

      number = number_match[1]
      response = response_match[1]

      # Find matching candidate for the given number
      candidate = Candidate.find_last_for_sms_number number

      # check if candidate is already unresponsive
      if candidate.is_unresponsive?
        raise 'Error candidate is unresponsive'
      end

      # update status based on response
      candidate.answered_from_sms! response, number

      message = candidate.response_message
    rescue => e
      logger.error e
    end

    render :text => message, :content_type => "text/plain"
  end
end
