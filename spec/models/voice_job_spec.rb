require 'spec_helper'

describe VoiceJob do

  before(:each) do
    @verboice = mock()
    Verboice.stubs(:from_config).returns(@verboice)
    @response = mock()
    @organization = Organization.make! :max_sms_retries => 10, :max_voice_retries => 20
    @channel = PigeonChannel.make! :channel_type => :verboice, :organization => @organization 
    @mission = Mission.make! :verboice_channel => @channel, :organization => @organization
  end

  after(:each) do
    Delayed::Job.delete_all
  end

  describe "successful" do
    before(:each) do
      @candidate = Candidate.make! :status => :pending, :voice_retries => 0, :mission => @mission
      @voice_job = VoiceJob.new @candidate.id
      @response.stubs(:[]).with('call_id').returns('123')
    end

    it "should call the volunteer" do
      @verboice.expects(:call).with(@candidate.volunteer.voice_channels.first.address, :status_callback_url => Rails.application.routes.url_helpers.verboice_status_callback_url, :channel => @channel.pigeon_name).returns(@response)

      @voice_job.perform
    end

    it "should increase retries if response is ok" do
      @verboice.stubs(:call).returns(@response)
      Timecop.freeze

      @voice_job.perform

      new_candidate = Candidate.find(@candidate.id)
      new_candidate.voice_retries.should == @candidate.voice_retries + 1
      new_candidate.last_voice_att.should == Time.now.utc
    end

    it "should enqueue next job" do
      @verboice.stubs(:call).returns(@response)

      @voice_job.perform

      jobs = Delayed::Job.all
      assert_equal 1, jobs.length

      job = jobs[0]
      job = YAML::load job.handler
      assert_equal 'VoiceJob', job.class.to_s
      assert_equal @candidate.id, job.candidate_id
    end

    it "should create Call with session id" do
      @verboice.stubs(:call).returns(@response)

      @voice_job.perform

      call = Call.last
      call.candidate.should eq(@candidate)
      call.session_id.should eq('123')
    end

  end

  describe "mission has no voice channel defined" do
    before(:each) do
      @mission = Mission.make! 
      @candidate = Candidate.make! :status => :pending, :voice_retries => 0, :mission => @mission
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

  describe "candidate not pending" do

    before(:each) do
      @candidate = Candidate.make! :status => :confirmed, :mission => @mission
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
      @volunteer = Volunteer.make! :organization => @organization
      @candidate = Candidate.make! :volunteer => @volunteer, :status => :pending, :sms_retries => @organization.max_sms_retries, :voice_retries => @organization.max_voice_retries, :mission => @mission
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

    it "should set no answer on candidate" do
      Candidate.any_instance.expects(:no_answer!)

      @voice_job.perform
    end
  end

  describe "candidate has retries but voice retries has hit limit" do
    before(:each) do
      @volunteer = Volunteer.make! :organization => @organization
      @candidate = Candidate.make! :volunteer => @volunteer, :status => :pending, :sms_retries => @organization.max_sms_retries - 1, :voice_retries => @organization.max_voice_retries, :mission => @mission
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
      @volunteer = Volunteer.make! :sms_channels => [], :organization => @organization
      @candidate = Candidate.make! :volunteer => @volunteer, :status => :pending, :voice_retries => @organization.max_voice_retries, :mission => @mission
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
      @candidate = Candidate.make! :status => :pending, :voice_retries => 1, :mission => @mission
      @voice_job = VoiceJob.new @candidate.id
      @verboice.expects(:call).raises(Exception, "Verboice Error")
    end

    it "should increase retries" do
      @voice_job.perform

      new_candidate = Candidate.find @candidate.id
      new_candidate.voice_retries.should == @candidate.voice_retries + 1
    end

    it "should not set last voice attempt" do
      Timecop.freeze

      @voice_job.perform

      new_candidate = Candidate.find @candidate.id
      new_candidate.last_voice_att.should == Time.now.utc
    end
  end

  describe "last call" do
    before(:each) do
      @candidate = Candidate.make! :status => :pending, :mission => @mission
      @last_call = Call.make! :candidate => @candidate
      @voice_job = VoiceJob.new @candidate.id
      @verboice.expects(:call_state).with(@last_call.session_id).returns(@response)
    end

    ["active", "queued"].each do |state|
      it "should not call candidate if last call is #{state}" do
        @response.expects(:[]).with("state").returns(state)
        @verboice.expects(:call).never

        @voice_job.perform
      end
    end

    ["completed", "failed"].each do |state|
      it "should call candidate if last call is #{state}" do
        @response.expects(:[]).with("state").returns(state)
        @verboice.expects(:call)

        @voice_job.perform
      end
    end
  end

  describe "verboice last call state fails" do
    before(:each) do
      @candidate = Candidate.make! :status => :pending, :mission => @mission
      @last_call = Call.make! :candidate => @candidate
      @voice_job = VoiceJob.new @candidate.id
      @verboice.expects(:call_state).with(@last_call.session_id).raises(Exception, "Verboice Error")
    end

    it "should initiate a new call" do
      @verboice.expects(:call)
      
      @voice_job.perform
    end
  end

  describe "with multiple voice numbers" do
    before(:each) do
      @volunteer = Volunteer.make! :voice_channels => [VoiceChannel.make, VoiceChannel.make]
      @voice_channels = @volunteer.voice_channels.sort_by(&:id)
      @candidate = Candidate.make! :status => :pending, :voice_retries => 0, :volunteer => @volunteer, :mission => @mission
      @status_callback_url = Rails.application.routes.url_helpers.verboice_status_callback_url
    end

    it "should call all the voice numbers in order" do
      @verboice.expects(:call).with(@voice_channels[0].address, :status_callback_url => @status_callback_url, :channel => @channel.pigeon_name).returns(@response)
      @response.stubs(:[]).with('call_id').returns('123')

      @voice_job = VoiceJob.new @candidate.id
      @voice_job.perform

      @verboice.expects(:call_state).with('123').returns('completed')
      @verboice.expects(:call).with(@voice_channels[1].address, :status_callback_url => @status_callback_url, :channel => @channel.pigeon_name).returns(@response)
      @response.stubs(:[]).with('call_id').returns('456')

      @voice_job = VoiceJob.new @candidate.id
      @voice_job.perform
    end

    it "should increment retries only when calling the last number in the list" do
      @verboice.expects(:call).returns(@response)
      @response.stubs(:[]).with('call_id').returns('123')

      @voice_job = VoiceJob.new @candidate.id
      @voice_job.perform

      new_candidate = Candidate.find(@candidate.id)
      new_candidate.voice_retries.should eq(@candidate.voice_retries)

      @verboice.expects(:call_state).with('123').returns('completed')
      @verboice.expects(:call).returns(@response)
      @response.stubs(:[]).with('call_id').returns('456')

      @voice_job = VoiceJob.new @candidate.id
      @voice_job.perform

      new_candidate = Candidate.find(@candidate.id)
      new_candidate.voice_retries.should eq(@candidate.voice_retries + 1)
    end

    describe "verboice api raises" do
      it "should call each number in order" do
        @verboice.expects(:call).with(@voice_channels[0].address, :status_callback_url => @status_callback_url, :channel => @channel.pigeon_name).
          raises(Exception, "Verboice Error")

        @voice_job = VoiceJob.new @candidate.id
        @voice_job.perform

        @verboice.expects(:call).with(@voice_channels[1].address, :status_callback_url => @status_callback_url, :channel => @channel.pigeon_name).
          raises(Exception, "Verboice Error")

        @voice_job = VoiceJob.new @candidate.id
        @voice_job.perform
      end

      it "should increment voice retries when calling the last number" do
        @verboice.stubs(:call).raises(Exception, "Verboice Error")

        lambda do
          @voice_job = VoiceJob.new @candidate.id
          @voice_job.perform
          @voice_job = VoiceJob.new @candidate.id
          @voice_job.perform
        end.should change {
          Candidate.find(@candidate.id).voice_retries
        }.by(1)
      end
    end
  end

end
