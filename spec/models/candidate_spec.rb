require 'spec_helper'

describe Candidate do
  
  describe "new candidate" do
    before(:each) do
      @candidate = Candidate.new
    end
  
    it "should have 0 retries" do
      @candidate.sms_retries.should == 0
      @candidate.voice_retries.should == 0
    end
    
    it "should be in pending state" do
      @candidate.is_pending?.should be true
    end
    
    it "should have no last sms or voice timestamps" do
      @candidate.last_sms_att.should be nil
      @candidate.last_voice_att.should be nil
    end
  end
  
  describe "candidate sms and voice number" do
    before(:each) do
      @candidate = Candidate.new
      @volunteer = Volunteer.new
      @candidate.volunteer = @volunteer
    end
    
    it "should tell if volunteer has sms number" do
      @volunteer.sms_number = nil
      @candidate.has_sms?.should be false
      @volunteer.sms_number = ''
      @candidate.has_sms?.should be false
      @volunteer.sms_number = '123'
      @candidate.has_sms?.should be true
    end
    
    it "should tell if volunteer has voice number" do
      @volunteer.voice_number = nil
      @candidate.has_voice?.should be false
      @volunteer.voice_number = ''
      @candidate.has_voice?.should be false
      @volunteer.voice_number = '123'
      @candidate.has_voice?.should be true
    end
  end
  
  describe "call" do
    before(:each) do
      @candidate = Candidate.new
      @candidate.stubs(:id).returns(10)
      @candidate.stubs(:has_sms?).returns(false)
      @candidate.stubs(:has_voice?).returns(false)
    end
    
    it "should send sms if it has sms" do
      @candidate.expects(:has_sms?).returns(true)
      
      @candidate.call
      
      jobs = Delayed::Job.all
      jobs.length.should == 1

      job = jobs[0]
      job = YAML::load job.handler
      job.class.to_s.should == 'SmsJob'
      job.candidate_id.should == @candidate.id
    end
    
    it "should call if it has voice" do
      @candidate.expects(:has_voice?).returns(true)
      
      @candidate.call
      
      jobs = Delayed::Job.all
      jobs.length.should == 1

      job = jobs[0]
      job = YAML::load job.handler
      job.class.to_s.should == 'VoiceJob'
      job.candidate_id.should == @candidate.id
    end
    
  end
  
end