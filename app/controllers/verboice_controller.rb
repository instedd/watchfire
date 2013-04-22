class VerboiceController < ApplicationController
  expose(:candidate) { Candidate.find_by_call_session_id params[:CallSid] }

  def plan
    if candidate.nil?
      # It's an unknown call session, find a mission to forward the call to
      @mission = find_mission_to_forward_call
      @channel = params[:Channel]
      @from = params[:From]
      render 'plan_forward'
    elsif candidate.mission.confirm_human?
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
    candidate.last_call_status = params[:CallStatus]
    candidate.save!

    head :ok
  end

private

  def find_mission_to_forward_call
    last_known_call = Call.find_by_voice_number(params[:From])
    if last_known_call
      mission = last_known_call.candidate.mission
    else
      channel = PigeonChannel.verboice.find_by_pigeon_name(params[:Channel])
      missions = Mission.where(:status => :running)
      if channel
        missions = missions.where(:organization_id => channel.organization)
      end
      mission = missions.order("updated_at DESC").first
    end

    if mission && mission.forward_address.present?
      mission
    else
      nil
    end
  end
end
