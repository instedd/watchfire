require 'spec_helper'

describe MissionJob do
  
  before(:each) do
    @valid_params = {:mission => Mission.new, :job => Delayed::Job.new}
  end
  
  it "should be valid with valid params" do
    MissionJob.new(@valid_params).valid?.should be true
  end
  
  it "should be invalid without mission" do
    MissionJob.new(@valid_params.except(:mission)).valid?.should be false
  end
  
  it "should be invalid without job" do
    MissionJob.new(@valid_params.except(:job)).valid?.should be false
  end
  
  it "should be invalid if there is another mission job with same mission and job" do
    mission = Mission.make!
    job = Delayed::Job.create!
    MissionJob.create! :mission => mission, :job => job
    MissionJob.new(:mission => mission, :job => job).valid?.should be false
  end
  
  it "should destroy job if destroyed" do
    mission = Mission.make!
    job = Delayed::Job.create!
    mission_job = MissionJob.create! :mission => mission, :job => job
    
    mission_job.destroy
    
    Mission.find(mission.id).should == mission
    Delayed::Job.find_by_id(job.id).should be_nil
  end
  
end
