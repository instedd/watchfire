class VerboiceController < ApplicationController
  
	http_basic_authenticate_with :name => app_config.basic_auth_name, :password => app_config.basic_auth_pwd

  def plan
    @candidate = Candidate.find_by_call_id params[:CallSid]
  end
  
  def callback
    match = params[:Digits].match /(1|2)/
    
    # digits don't match required response, play 'plan' again
    unless match
      render "plan"
      return
    end
    
    # find candidate based on call id
    candidate = Candidate.find_by_call_id params[:CallSid]
    
    # update status according to response
    answer = match[1].to_i
    
    if answer == 1
      candidate.update_status :confirmed
    else
      candidate.update_status :denied
    end
  end

end
