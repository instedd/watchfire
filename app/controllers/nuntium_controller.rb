class NuntiumController < ApplicationController
  
  def receive
    begin
      config = Watchfire::Application.config
      from = params[:from]
      body = params[:body]
      
      # parse fields
      number_match = from.match /sms:\/\/(\d+)/
      response_match = body.match /(1|2)/
    
      raise 'Error parsing number' unless number_match
      raise 'Error parsing response' unless response_match
    
      number = number_match[1]
      response = response_match[1].to_i
      
      # find matching candidate for the given number
      candidate = Candidate.find_last_for_sms_number number
      
      # check if candidate is unresponsive
      if candidate.is_unresponsive?
        raise 'Error candidate is unresponsive'
      end
    
      # update status based on response
      if response == 1
        candidate.status = :confirmed
      elsif response == 2
        candidate.status = :denied
      end
      candidate.save!
      
    rescue => e
      logger.error e
    end
    
    render :nothing => true
  end
  
end
