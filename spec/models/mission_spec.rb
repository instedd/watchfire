require 'spec_helper'

describe Mission do

  it "should call volunteers" do
    mission = Mission.new
    mission.stubs(:save!).returns(true)
    
    c1 = mock('c1')
    c2 = mock('c2')
    
    mission.expects(:pending_candidates).returns([c1,c2])
    
    c1.expects(:call)
    c2.expects(:call)
    
    mission.call_volunteers
    
    mission.is_running?.should be true
  end
  
  it "should tell pending candidates" do
    mission = Mission.make!
    c1 = Candidate.make! :mission => mission, :status => :pending
    c2 = Candidate.make! :mission => mission, :status => :unresponsive
    c3 = Candidate.make! :mission => mission, :status => :pending
    
    volunteers = mission.pending_candidates
    
    volunteers.length.should == 2
    volunteers.should include c1
    volunteers.should include c3
  end
  
  it "should stop calling volunteers" do
    mission = Mission.make! :status => :running
    mission.stop_calling_volunteers
    mission.reload.is_paused?.should be true
  end
  
end
