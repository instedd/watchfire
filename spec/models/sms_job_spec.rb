require 'spec_helper'

describe SmsJob do

  before(:each) do
    @nuntium = mock()
    Nuntium.stubs(:from_config).returns(@nuntium)
    @organization = Organization.make! :max_sms_retries => 10, :max_voice_retries => 20
    @channel = PigeonChannel.make! :channel_type => :nuntium, :organization => @organization
    @mission = Mission.make! :nuntium_channel => @channel, :organization => @organization
  end

  after(:each) do
    Delayed::Job.delete_all
  end

  describe "successful" do
    before(:each) do
      @candidate = Candidate.make! :status => :pending, :sms_retries => 0, :mission => @mission
      @sms_job = SmsJob.new @candidate.id
    end

    it "should send sms to volunteer" do
      @nuntium.expects(:send_ao)

      @sms_job.perform
    end

    it "should increase retries if response is ok" do
      @nuntium.stubs(:send_ao)
      Timecop.freeze

      @sms_job.perform

      new_candidate = Candidate.find(@candidate.id)
      new_candidate.sms_retries.should == @candidate.sms_retries + 1
      new_candidate.last_sms_att.should == Time.now.utc
    end

    it "should enqueue next job" do
      @nuntium.stubs(:send_ao)

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
        message[:to] == "sms://#{@candidate.volunteer.sms_channels.first.address}"
      end

      @sms_job.perform
    end

    it "should send sms with appropiate text" do
      @nuntium.expects(:send_ao).with do |message|
        message[:body] == @candidate.mission.sms_message
      end

      @sms_job.perform
    end

    it "should send sms with organization" do
      @nuntium.expects(:send_ao).with do |message|
        message[:organization_id] == @organization.id
      end

      @sms_job.perform
    end

    it "should send sms with the channel suggestion for the mission" do
      @nuntium.expects(:send_ao).with do |message|
        message[:suggested_channel] == @channel.pigeon_name
      end

      @sms_job.perform
    end
  end

  describe "mission does not have an sms channel" do
    before(:each) do
      @mission = Mission.make!
      @candidate = Candidate.make! :status => :pending, :sms_retries => 0, :mission => @mission
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

  describe "candidate not pending" do

    before(:each) do
      @candidate = Candidate.make! :status => :confirmed, :mission => @mission
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
      @volunteer = Volunteer.make! :organization => @organization
      @candidate = Candidate.make! :volunteer => @volunteer, :status => :pending, :sms_retries => @organization.max_sms_retries, :voice_retries => @organization.max_voice_retries, :mission => @mission
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

    it "should set no answer on candidate" do
      Candidate.any_instance.expects(:no_answer!)

      @sms_job.perform
    end
  end

  describe "candidate has retries but sms retries has hit limit" do
    before(:each) do
      @volunteer = Volunteer.make! :organization => @organization
      @candidate = Candidate.make! :volunteer => @volunteer, :status => :pending, :sms_retries => @organization.max_sms_retries, :voice_retries => @organization.max_voice_retries - 1, :mission => @mission
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

  describe "candidate has run out of sms retries and doesn't have voice" do
    before(:each) do
      @volunteer = Volunteer.make! :voice_channels => [], :organization => @organization
      @candidate = Candidate.make! :volunteer => @volunteer, :status => :pending, :sms_retries => @organization.max_sms_retries, :mission => @mission
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

    it "should set status to unresponsive" do
      @sms_job.perform
      @candidate.reload.is_unresponsive?.should be true
    end
  end

  describe "nuntium error" do

    before(:each) do
      @candidate = Candidate.make! :status => :pending, :sms_retries => 1, :mission => @mission
      @sms_job = SmsJob.new @candidate.id

      @nuntium.expects(:send_ao).raises(Nuntium::Exception, "Nuntium Error")
    end

    it "should increase retries" do
      @sms_job.perform

      new_candidate = Candidate.find @candidate.id
      new_candidate.sms_retries.should == @candidate.sms_retries + 1
    end

    it "should set last sms attempt" do
			Timecop.freeze

			@sms_job.perform

      new_candidate = Candidate.find @candidate.id
      new_candidate.last_sms_att.should == Time.now.utc
    end

  end

  describe "with multiple sms phone numbers" do
    before(:each) do
      @volunteer = Volunteer.make! :sms_channels => [SmsChannel.make, SmsChannel.make]
      @candidate = Candidate.make! :status => :pending, :sms_retries => 0, :volunteer => @volunteer, :mission => @mission
      @sms_job = SmsJob.new @candidate.id
    end

    it "should send sms to each number" do
      @candidate.volunteer.sms_channels.each do |sms_channel|
        @nuntium.expects(:send_ao).with do |message|
          message[:to] == "sms://#{sms_channel.address}"
        end
      end

      @sms_job.perform
    end

    it "should increase sms retries by 1 regardless of number of channels" do
      @nuntium.stubs(:send_ao).twice

      @sms_job.perform

      new_candidate = Candidate.find(@candidate.id)
      new_candidate.sms_retries.should == @candidate.sms_retries + 1
    end

    describe "on nuntium error" do
      it "should try to send sms to all sms numbers" do
        @nuntium.stubs(:send_ao).raises(Nuntium::Exception, "Nuntium error").then.returns

        @sms_job.perform
      end
    end
  end

end
