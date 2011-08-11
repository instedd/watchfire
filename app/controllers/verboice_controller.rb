class VerboiceController < ApplicationController
  
  def plan
  end
  
  def callback
    match = params[:Digits].match /(1|2)/
    
    unless match
      render "plan"
      return
    end
    
    candidate = Candidate.find_by_call_id params[:CallSid]
    answer = match[1].to_i
    
    if answer == 1
      candidate.status = :confirmed
    else
      candidate.status = :denied
    end
    
    candidate.save!
  end

end
