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

    it "should be active" do
      @candidate.active.should be_true
    end
  end

  describe "candidate sms and voice number" do
    before(:each) do
      @candidate = Candidate.new
      @volunteer = Volunteer.new
      @candidate.volunteer = @volunteer
    end

    it "should tell if volunteer has sms number" do
      @volunteer.sms_channels = []
      @candidate.has_sms?.should be false
      @volunteer.sms_channels << SmsChannel.make
      @candidate.has_sms?.should be true
    end

    it "should tell if volunteer has voice number" do
      @volunteer.voice_channels = []
      @candidate.has_voice?.should be false
      @volunteer.voice_channels << VoiceChannel.make
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
      @organization = Organization.new :max_sms_retries => 10, :max_voice_retries => 20
      @candidate = Candidate.new
      @candidate.volunteer = Volunteer.new :sms_channels => [SmsChannel.make], :voice_channels => [VoiceChannel.make], :organization => @organization
    end

    it "should have retries if sms retry count is below max" do
      @candidate.sms_retries = @organization.max_sms_retries - 1
      @candidate.has_retries?.should be true
      @candidate.voice_retries = @organization.max_voice_retries
      @candidate.has_retries?.should be true
    end

    it "should have retries if voice retry count is below max" do
      @candidate.voice_retries = @organization.max_voice_retries - 1
      @candidate.has_retries?.should be true
      @candidate.sms_retries = @organization.max_sms_retries
      @candidate.has_retries?.should be true
    end

    it "should not have retries if sms and voice retry count is at max" do
      @candidate.sms_retries = @organization.max_sms_retries
      @candidate.voice_retries = @organization.max_voice_retries
      @candidate.has_retries?.should be false
    end

    it "should have sms/voice retries if retries is below max" do
      @candidate.sms_retries = @organization.max_sms_retries - 1
      @candidate.has_sms_retries?.should be true
      @candidate.voice_retries = @organization.max_voice_retries - 1
      @candidate.has_voice_retries?.should be true
    end

    it "should not have sms/voice retries if retries is beyond max" do
      @candidate.sms_retries = @organization.max_sms_retries + 1
      @candidate.has_sms_retries?.should be false
      @candidate.voice_retries = @organization.max_voice_retries + 1
      @candidate.has_voice_retries?.should be false
    end

    it "should not have sms retries if volunteer doesn't have sms" do
      @candidate.volunteer.sms_channels = []
      @candidate.has_sms_retries?.should be false
    end

    it "should not have voice retries if volunteer doesn't have voice" do
      @candidate.volunteer.voice_channels = []
      @candidate.has_voice_retries?.should be false
    end
  end

  describe "update status" do
    before(:each) do
      @candidate = Candidate.make!
      # FIXME
      # @candidate.mission.expects(:check_for_more_volunteers)
      Timecop.freeze
    end

    it "should handle 'yes' response from sms" do
      pending "decide what to do with the answered_from_* api"
      @candidate.answered_from_sms! "yes"

      @candidate.confirmed?.should be_true
      @candidate.answered_from.should eq(@candidate.volunteer.sms_number)
      @candidate.answered_at.should eq(Time.now.utc)
    end

    it "should handle 'no' response from sms" do
      pending "decide what to do with the answered_from_* api"
      @candidate.answered_from_sms! "no"

      @candidate.denied?.should be_true
      @candidate.answered_from.should eq(@candidate.volunteer.sms_number)
      @candidate.answered_at.should eq(Time.now.utc)
    end

    it "should handle '1' response from voice" do
      pending "decide what to do with the answered_from_* api"
      @candidate.answered_from_voice! "1"

      @candidate.confirmed?.should be_true
      @candidate.answered_from.should eq(@candidate.volunteer.voice_number)
      @candidate.answered_at.should eq(Time.now.utc)
    end

    it "should handle '2' response from voice" do
      pending "decide what to do with the answered_from_* api"
      @candidate.answered_from_voice! "2"

      @candidate.denied?.should be_true
      @candidate.answered_from.should eq(@candidate.volunteer.voice_number)
      @candidate.answered_at.should eq(Time.now.utc)
    end

    it "should handle no answer" do
      @candidate.no_answer!

      @candidate.unresponsive?.should be_true
    end
  end

  describe "find by call session id" do
    before(:each) do
      @candidate = Candidate.make!
      @call_1 = Call.make! :candidate => @candidate
      @call_2 = Call.make! :candidate => @candidate
    end

    it "should find candidate by any of its calls" do
      Candidate.find_by_call_session_id(@call_1.session_id).should eq(@candidate)
      Candidate.find_by_call_session_id(@call_2.session_id).should eq(@candidate)
    end

    it "should return nil if doesn't exist" do
      Candidate.find_by_call_session_id("foo").should be_nil
    end
  end

  it "should destroy dependent calls" do
    candidate = Candidate.make!
    call_1 = Call.make! :candidate => candidate
    call_2 = Call.make! :candidate => candidate
    call_3 = Call.make!

    Call.all.size.should eq(3)

    candidate.destroy

    Call.all.size.should eq(1)
    Call.first.should eq(call_3)
  end

  it "should tell voice response based on status" do
    candidate = Candidate.new
    candidate.status = :confirmed
    candidate.response_message.should eq(I18n.t(:response_confirmed))
    candidate.status = :denied
    candidate.response_message.should eq(I18n.t(:response_denied))
  end

  it "should enable candidate" do
    candidate = Candidate.make!
    candidate.enable!
    candidate.active.should be_true
  end

  it "should disable candidate" do
    candidate = Candidate.make!
    candidate.disable!
    candidate.active.should be_false
  end

end
