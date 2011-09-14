require 'spec_helper'

describe VoiceJob do
  
  before(:each) do
    @config =  Watchfire::Application.config
    @verboice = mock()
    Verboice.stubs(:new).returns(@verboice)
    @response = mock()
  end
  
  after(:each) do
    Delayed::Job.delete_all
  end
  
  describe "successful" do
    before(:each) do
      @candidate = Candidate.make! :status => :pending, :voice_retries => 0
      @voice_job = VoiceJob.new @candidate.id
      @response.stubs(:[]).with('call_id').returns('123')
    end
    
    it "should call the volunteer" do
      @response.stubs(:code).returns(200)    
      @verboice.expects(:call).with(@candidate.volunteer.voice_number).returns(@response)
      
      @voice_job.perform
    end
    
    it "should increase retries if response is ok" do
      @verboice.stubs(:call).returns(@response)
      @response.expects(:code).returns(200)
      Timecop.freeze
      
      @voice_job.perform
      
      new_candidate = Candidate.find(@candidate.id)
      new_candidate.voice_retries.should == @candidate.voice_retries + 1
      new_candidate.last_voice_att.should == Time.now.utc  
    end
    
    it "should enqueue next job" do
      @verboice.stubs(:call).returns(@response)
      @response.stubs(:code).returns(200)
      
      @voice_job.perform
      
      jobs = Delayed::Job.all
      assert_equal 1, jobs.length

      job = jobs[0]
      job = YAML::load job.handler
      assert_equal 'VoiceJob', job.class.to_s
      assert_equal @candidate.id, job.candidate_id
    end
    
    it "should save call id" do
      @verboice.stubs(:call).returns(@response)
      @response.stubs(:code).returns(200)
      
      @voice_job.perform
      
      @candidate.reload.call_id.should == '123'
    end
    
  end
  
  describe "candidate not pending" do
    
    before(:each) do
      @candidate = Candidate.make! :status => :confirmed
      @voice_job = VoiceJob.new @candidate.id
    end
    
    it "should not call the volunteer" do
      @verboice.expects(:call).never
      
      @voice_job.perform
    end
    
    it "should not enqueue new job" do
      @voice_job.perform
      
      Delayed::Job.count.should == 0
    end
    
    it "should remain same state" do
      @voice_job.perform
      
      @candidate.reload.is_confirmed?.should be true
    end
    
  end
  
  describe "candidate has run out of retries" do
    before(:each) do
      @candidate = Candidate.make! :status => :pending, :sms_retries => @config.max_sms_retries, :voice_retries => @config.max_voice_retries
      @voice_job = VoiceJob.new @candidate.id
    end
    
    it "should not call the volunteer" do
      @verboice.expects(:call).never
      
      @voice_job.perform
    end
    
    it "should set status to unresponsive" do
      @voice_job.perform
      
      @candidate.reload.is_unresponsive?.should be true
    end
    
    it "should not enqueue new job" do
      @voice_job.perform
      
      Delayed::Job.count.should == 0
    end
    
    it "should call update_status on candidate" do
      Candidate.any_instance.expects(:update_status)
      
      @voice_job.perform
    end
  end
  
  describe "candidate has retries but voice retries has hit limit" do
    before(:each) do
      @candidate = Candidate.make! :status => :pending, :sms_retries => @config.max_sms_retries - 1, :voice_retries => @config.max_voice_retries
      @voice_job = VoiceJob.new @candidate.id
    end
    
    it "should not call the volunteer" do
      @verboice.expects(:call).never
      @voice_job.perform
    end
    
    it "should not enqueue new job" do
      @voice_job.perform
      Delayed::Job.count.should == 0
    end
  end
  
  describe "candidate has run out of voice retries and doesn't have sms" do
    before(:each) do
      @volunteer = Volunteer.make! :sms_number => nil
      @candidate = Candidate.make! :status => :pending, :voice_retries => @config.max_voice_retries, :volunteer => @volunteer
      @voice_job = VoiceJob.new @candidate.id
    end
    
    it "should not call the volunteer" do
      @verboice.expects(:call).never
      @voice_job.perform
    end
    
    it "should not enqueue new job" do
      @voice_job.perform
      Delayed::Job.count.should == 0
    end
    
    it "should set status to unresponsive" do
      @voice_job.perform
      @candidate.reload.is_unresponsive?.should be true
    end
  end
  
  describe "verboice bad response" do
    
    before(:each) do
      @candidate = Candidate.make! :status => :pending, :voice_retries => 1
      @voice_job = VoiceJob.new @candidate.id
      
      @verboice.stubs(:call).returns(@response)
      @response.stubs(:code).returns(400)
    end
    
    it "should not increase retries" do
      @voice_job.perform
      
      new_candidate = Candidate.find @candidate.id
      new_candidate.voice_retries.should == @candidate.voice_retries
    end
    
    it "should not set last voice attempt" do
      @voice_job.perform
      
      new_candidate = Candidate.find @candidate.id
      new_candidate.last_voice_att.should == @candidate.last_voice_att
    end
    
  end
  
end
