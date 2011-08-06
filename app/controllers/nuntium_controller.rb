class NuntiumController < ApplicationController
  
  def receive
    from = params[:from]
    body = params[:body]
    
    number_match = from.match /sms:\/\/(\d+)/
    response_match = body.match /(1|2)/
    
    return unless number_match || response_match
    
    number = number_match[1]
    response = response_match[1].to_i
    
    candidate = Candidate.joins(:volunteer).where(:volunteers => {:sms_number => number}).order('last_sms_att DESC').first
    
    if response == 1
      candidate.status = :confirmed
    elsif response == 2
      candidate.status = :denied
    end
    
    candidate.save!
    
    render :nothing => true
  end

end
