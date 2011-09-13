require 'spec_helper'

describe SmsJob do
  
  before(:each) do
    @config =  Watchfire::Application.config
    @nuntium = mock()
    Nuntium.stubs(:new).returns(@nuntium)
    @response = mock()
  end
  
  after(:each) do
    Delayed::Job.delete_all
  end
  
  describe "successful" do
    before(:each) do
      @candidate = Candidate.make! :status => :pending, :sms_retries => 0
      @sms_job = SmsJob.new @candidate.id
    end
    
    it "should send sms to volunteer" do
      @response.stubs(:code).returns(200)    
      @nuntium.expects(:send_ao).returns(@response)
      
      @sms_job.perform
    end
    
    it "should increase retries if response is ok" do
      @nuntium.stubs(:send_ao).returns(@response)
      @response.expects(:code).returns(200)
      Timecop.freeze
      
      @sms_job.perform
      
      new_candidate = Candidate.find(@candidate.id)
      new_candidate.sms_retries.should == @candidate.sms_retries + 1
      new_candidate.last_sms_att.should == Time.now.utc  
    end
    
    it "should enqueue next job" do
      @nuntium.stubs(:send_ao).returns(@response)
      @response.stubs(:code).returns(200)
      
      @sms_job.perform
      
      jobs = Delayed::Job.all
      assert_equal 1, jobs.length

      job = jobs[0]
      job = YAML::load job.handler
      assert_equal 'SmsJob', job.class.to_s
      assert_equal @candidate.id, job.candidate_id
    end
    
    it "should send sms to the candidate sms phone number" do
      @nuntium.expects(:send_ao).with do |message|
        message[:to] == "sms://#{@candidate.volunteer.sms_number}"
      end.returns(@response)
      @response.stubs(:code).returns(200)
      
      @sms_job.perform
    end
    
    it "should send sms with appropiate text" do
      @nuntium.expects(:send_ao).with do |message|
        message[:body] == @candidate.mission.sms_message
      end.returns(@response)
      @response.stubs(:code).returns(200)
      
      @sms_job.perform
    end
  end
  
  describe "candidate not pending" do
    
    before(:each) do
      @candidate = Candidate.make! :status => :confirmed
      @sms_job = SmsJob.new @candidate.id
    end
    
    it "should not send sms" do
      @nuntium.expects(:send_ao).never
      
      @sms_job.perform
    end
    
    it "should not enqueue new job" do
      @sms_job.perform
      
      Delayed::Job.count.should == 0
    end
    
    it "should remain same state" do
      @sms_job.perform
      
      new_candidate = Candidate.find(@candidate.id)
      new_candidate.is_confirmed?.should be true
    end
    
  end
  
  describe "candidate has run out of retries" do
    before(:each) do
      @candidate = Candidate.make! :status => :pending, :sms_retries => @config.max_sms_retries, :voice_retries => @config.max_voice_retries
      @sms_job = SmsJob.new @candidate.id
    end
    
    it "should not send sms" do
      @nuntium.expects(:send_ao).never
      
      @sms_job.perform
    end
    
    it "should set status to unresponsive" do
      @sms_job.perform
      
      @candidate.reload.is_unresponsive?.should be true
    end
    
    it "should not enqueue new job" do
      @sms_job.perform
      
      Delayed::Job.count.should == 0
    end
    
    it "should call update_status on candidate" do
      Candidate.any_instance.expects(:update_status)
      
      @sms_job.perform
    end
    
  end
  
  describe "candidate has retries but sms retries has hit limit" do
    before(:each) do
      @candidate = Candidate.make! :status => :pending, :sms_retries => @config.max_sms_retries, :voice_retries => @config.max_voice_retries - 1
      @sms_job = SmsJob.new @candidate.id
    end
    
    it "should not send sms" do
      @nuntium.expects(:send_ao).never
      @sms_job.perform
    end
    
    it "should not enqueue new job" do
      @sms_job.perform
      Delayed::Job.count.should == 0
    end
  end
  
  describe "nuntium bad response" do
    
    before(:each) do
      @candidate = Candidate.make! :status => :pending, :sms_retries => 1
      @sms_job = SmsJob.new @candidate.id
      
      @nuntium.stubs(:send_ao).returns(@response)
      @response.stubs(:code).returns(400)
    end
    
    it "should not increase retries" do
      @sms_job.perform
      
      new_candidate = Candidate.find @candidate.id
      new_candidate.sms_retries.should == @candidate.sms_retries
    end
    
    it "should not set last sms attempt" do
      @sms_job.perform
      
      new_candidate = Candidate.find @candidate.id
      new_candidate.last_sms_att.should == @candidate.last_sms_att
    end
    
  end
  
end