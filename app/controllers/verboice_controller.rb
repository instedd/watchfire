class VerboiceController < ApplicationController
  before_filter :load_candidate

  def plan
  end
  
  def callback    
    # look for user response based on digits
    match = params[:Digits].match /(1|2)/
    
    # digits don't match required response, play 'plan' again
    unless match
      render "plan"
      return
    end
    
    # update status according to response
    answer = match[1].to_i
    
    if answer == 1
      @candidate.update_status :confirmed
    else
      @candidate.update_status :denied
    end
  end
  
  private
  
  def load_candidate
    @candidate = Candidate.find_by_call_session_id params[:CallSid]
  end

end
