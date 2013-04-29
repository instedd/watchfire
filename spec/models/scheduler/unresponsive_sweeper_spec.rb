require 'spec_helper'

describe Scheduler::UnresponsiveSweeper do
  before(:each) do
    Timecop.freeze

    @organization = Organization.make! max_sms_retries: 3, max_voice_retries: 3,
      sms_timeout: 5, voice_timeout: 5
    @mission = Mission.make! organization: @organization
    @scheduler = mock
    @scheduler.stubs(:organization).returns(@organization)
    @scheduler.stubs(:has_sms_channels?).returns(true)
    @scheduler.stubs(:has_voice_channels?).returns(true)
    @sweeper = Scheduler::UnresponsiveSweeper.new(@mission, @scheduler)
  end

  def make_unresponsive_candidate(params = {})
    sms_numbers = params.delete(:sms_numbers) { 1 }
    voice_numbers = params.delete(:voice_numbers) { 1 }
    has_sms = sms_numbers > 0
    has_voice = voice_numbers > 0
    volunteer = Volunteer.make! organization: @organization, 
      sms_channels: sms_numbers.times.map { SmsChannel.make },
      voice_channels: voice_numbers.times.map { VoiceChannel.make }
    Candidate.make!({ 
      mission: @mission, volunteer: volunteer, status: :pending,
      sms_retries: (has_sms and 3 or 0),
      voice_retries: (has_voice and 3 or 0), 
      last_sms_att: (has_sms and 5.minutes.ago or nil), 
      last_voice_att: (has_voice and 5.minutes.ago or nil)
    }.merge(params))
  end

  describe "unresponsive_candidates" do
    it "should return pending candidates with no retries and expired timeouts" do
      @c1 = make_unresponsive_candidate
      @c2 = make_unresponsive_candidate status: :denied

      @sweeper.unresponsive_candidates.should include(@c1)
      @sweeper.unresponsive_candidates.should_not include(@c2)
    end

    it "should not return candidates with SMS numbers and SMS retries left" do
      @c1 = make_unresponsive_candidate sms_retries: 2, voice_numbers: 0

      @sweeper.unresponsive_candidates.should_not include(@c1)
    end

    it "should not return candidates with voice numbers and voice retries left" do
      @c1 = make_unresponsive_candidate voice_retries: 2, sms_numbers: 0

      @sweeper.unresponsive_candidates.should_not include(@c1)
    end

    it "should not return candidates with no retries but no expired timeouts" do
      @c1 = make_unresponsive_candidate last_sms_att: Time.now, 
        last_voice_att: Time.now

      @sweeper.unresponsive_candidates.should_not include(@c1)
    end
  end

  describe "perform" do
    it "should return false if no candidates were marked unresponsive" do
      @sweeper.perform.should be_false
    end

    it "should return true if any candidates were marked as unresponsive" do
      @c1 = make_unresponsive_candidate
      @sweeper.perform.should be_true
    end

    it "should mark each unresponsive candidates" do
      @c1 = make_unresponsive_candidate
      @c1.expects(:no_answer!)

      @sweeper.expects(:unresponsive_candidates).returns([@c1])
      @sweeper.perform
    end
  end

  describe "next_deadline" do
    it "should return nil if there are no pending candidates" do
      @sweeper.next_deadline.should be_nil
    end

    it "should return nil if all candidates still have retries left" do
      @c1 = make_unresponsive_candidate sms_retries: 1
      @sweeper.next_deadline.should be_nil
    end

    it "when there are no more retries left, should return the latest deadline of sms and voice" do
      @c1 = make_unresponsive_candidate last_sms_att: 1.minutes.ago, 
        last_voice_att: 2.minutes.ago
      @sweeper.next_deadline.should eq(4.minutes.from_now)
    end

    it "when the candidates have no SMS, should ignore SMS retries" do
      @c1 = make_unresponsive_candidate last_sms_att: 7.minutes.ago, 
        last_voice_att: 3.minutes.ago, sms_numbers: 0, sms_retries: 3
      @sweeper.next_deadline.should eq(2.minutes.from_now)
    end

    it "when the candidates have no voice, should ignore voice retries" do
      @c1 = make_unresponsive_candidate last_sms_att: 3.minutes.ago, 
        last_voice_att: 7.minutes.ago, voice_numbers: 0, voice_retries: 3
      @sweeper.next_deadline.should eq(2.minutes.from_now)
    end
  end
end

