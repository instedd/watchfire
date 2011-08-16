require 'spec_helper'

describe CandidateJob do
  
  it "should link job with candidates mission" do
    candidate = Candidate.make!
    delayed_job = Delayed::Job.create!
    candidate_job = CandidateJob.new(candidate.id)
    
    candidate_job.enqueue(delayed_job)
    
    mission_job = MissionJob.first
    mission_job.mission.should == candidate.mission
    mission_job.job.should == delayed_job
  end
  
  
end
