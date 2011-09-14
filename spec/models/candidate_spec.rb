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
      Delayed::Job.expects(:enqueue).with(SmsJob.new(@candidate.id))
      
      @candidate.call
    end
    
    it "should call if it has voice" do
      @candidate.expects(:has_voice?).returns(true)
      Delayed::Job.expects(:enqueue).with(VoiceJob.new(@candidate.id))
      
      @candidate.call
    end
  end
  
  describe "has retries" do
    before(:each) do
      @candidate = Candidate.new
      @candidate.volunteer = Volunteer.new :sms_number => '123', :voice_number => '456'
      @config = Watchfire::Application.config
    end
    
    it "should have retries if sms retry count is below max" do
      @candidate.sms_retries = @config.max_sms_retries - 1
      @candidate.has_retries?.should be true
      @candidate.voice_retries = @config.max_voice_retries
      @candidate.has_retries?.should be true
    end
    
    it "should have retries if voice retry count is below max" do
      @candidate.voice_retries = @config.max_voice_retries - 1
      @candidate.has_retries?.should be true
      @candidate.sms_retries = @config.max_sms_retries
      @candidate.has_retries?.should be true
    end
    
    it "should not have retries if sms and voice retry count is at max" do
      @candidate.sms_retries = @config.max_sms_retries
      @candidate.voice_retries = @config.max_voice_retries
      @candidate.has_retries?.should be false
    end
    
    it "should have sms/voice retries if retries is below max" do
      @candidate.sms_retries = @config.max_sms_retries - 1
      @candidate.has_sms_retries?.should be true
      @candidate.voice_retries = @config.max_voice_retries - 1
      @candidate.has_voice_retries?.should be true
    end
    
    it "should not have sms/voice retries if retries is beyond max" do
      @candidate.sms_retries = @config.max_sms_retries + 1
      @candidate.has_sms_retries?.should be false
      @candidate.voice_retries = @config.max_voice_retries + 1
      @candidate.has_voice_retries?.should be false
    end
    
    it "should not have sms retries if volunteer doesn't have sms" do
      @candidate.volunteer.sms_number = nil
      @candidate.has_sms_retries?.should be false
    end
    
    it "should not have voice retries if volunteer doesn't have voice" do
      @candidate.volunteer.voice_number = nil
      @candidate.has_voice_retries?.should be false
    end
    
  end
  
  describe "update status" do
    
    before(:each) do
      @candidate = Candidate.new
      @mission = Mission.new
      @candidate.mission = @mission
    end
    
    %w(confirmed pending denied unresponsive).each do |status|
      it "should update status to #{status}" do
        @candidate.expects(:save!)
        @mission.stubs(:check_for_more_volunteers)
        @candidate.update_status status
        @candidate.send("is_#{status}?").should be true
      end
    end
    
    it "should check for more volunteers in mission" do
      @candidate.stubs(:save!)
      @mission.expects(:check_for_more_volunteers)
      @candidate.update_status :pending
    end
    
  end
  
end
