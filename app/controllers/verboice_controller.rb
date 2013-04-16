class VerboiceController < ApplicationController
  expose(:candidate) { Candidate.find_by_call_session_id params[:CallSid] }

  def plan
    if candidate.mission.confirm_human?
      render 'plan_before_confirmation'
    else
      render 'plan_no_confirmation'
    end
  end

  def plan_after_confirmation
  end

  def callback
    # Look for user response based on digits
    match = params[:Digits].match(/(1|2)/)

    # Digits don't match required response, play 'plan' again
    unless match
      render "plan_no_confirmation"
      return
    end

    # Update status according to response
    response = match[1]
    candidate.answered_from_voice! response, Call.find_by_session_id(params[:CallSid]).voice_number
  end

  def status_callback
    candidate.voice_status = params[:CallStatus]
    candidate.save!

    head :ok
  end
end
