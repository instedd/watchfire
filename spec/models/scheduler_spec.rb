require 'spec_helper'

describe "Scheduler" do
  before(:each) do
    @organization = Organization.make!
    @mission = Mission.make! organization: @organization
  end

  describe "call_status_update" do
    it "should forward the status update to the organization scheduler" do
      session_id = '123'
      call_status = 'failed'
      @candidate = Candidate.make! mission: @mission
      @call = CurrentCall.make! candidate: @candidate, session_id: session_id
      org_sched = mock
      org_sched.expects(:call_status_update).with(session_id, call_status)
      Scheduler.expects(:organization).with(@organization.id).returns(org_sched)

      Scheduler.call_status_update(session_id, call_status)
    end
  end
  
end
