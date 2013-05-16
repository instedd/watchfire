class VerboiceController < ApplicationController
  expose(:current_call) { CurrentCall.find_by_session_id params[:CallSid] }
  expose(:candidate) { current_call.try(:candidate) }

  before_filter :forward_call_if_unknown, except: [:status_callback]

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
    candidate.answered_from_voice! response, current_call.voice_number
  end

  def status_callback
    SchedulerAdvisor.call_status_update params[:CallSid], params[:CallStatus]

    head :ok
  end

private

  def forward_call_if_unknown
    if current_call.nil?
      # It's an unknown call session, find a mission to forward the call to
      @mission = find_mission_to_forward_call
      @channel = params[:Channel]
      @from = params[:From]
      render 'plan_forward'
    end
  end

  def find_mission_to_forward_call
    last_called_candidate = Candidate.find_last_for_voice_number(params[:From])
    if last_called_candidate
      mission = last_called_candidate.mission
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
