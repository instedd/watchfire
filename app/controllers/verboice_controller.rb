class VerboiceController < ApplicationController
  expose(:candidate) { Candidate.find_by_call_session_id params[:CallSid] }

  def plan
  end

  def callback
    # Look for user response based on digits
    match = params[:Digits].match /(1|2)/

    # Digits don't match required response, play 'plan' again
    unless match
      render "plan"
      return
    end

    # Update status according to response
    response = match[1]
    candidate.answered_from_voice! response
  end

  def status_callback
    candidate.voice_status = params[:CallStatus]
    candidate.save!

    head :ok
  end
end
