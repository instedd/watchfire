require 'spec_helper'

module Scheduler
  describe SmsSender do
    before(:each) do
      Timecop.freeze(Date.today)

      @organization = Organization.make! sms_timeout: 5, max_sms_retries: 3
      @mission = Mission.make! organization: @organization
      @sender = Scheduler::SmsSender.new(@mission)
    end

    describe "find_candidates_to_sms" do
      it "should return pending candidates" do
        @c1 = Candidate.make! mission: @mission, status: :pending
        @c2 = Candidate.make! mission: @mission, status: :denied

        @sender.find_candidates_to_sms.should include(@c1)
        @sender.find_candidates_to_sms.should_not include(@c2)
      end

      it "should return candidates who we never sent an SMS to" do
        @c1 = Candidate.make! mission: @mission, status: :pending,
          last_sms_att: nil, sms_retries: 0

        @sender.find_candidates_to_sms.should eq([@c1])
      end

      it "should return candidates with expired SMS timeout" do
        @c1 = Candidate.make! mission: @mission, status: :pending,
          last_sms_att: (@organization.sms_timeout + 1).minutes.ago
        @c2 = Candidate.make! mission: @mission, status: :pending,
          last_sms_att: (@organization.sms_timeout - 1).minutes.ago

        @sender.find_candidates_to_sms.should include(@c1)
        @sender.find_candidates_to_sms.should_not include(@c2)
      end

      it "should only return candidates that have SMS numbers" do
        @vol1 = Volunteer.make! sms_channels: []
        @vol2 = Volunteer.make! sms_channels: [SmsChannel.make]

        @c1 = Candidate.make! mission: @mission, volunteer: @vol1
        @c2 = Candidate.make! mission: @mission, volunteer: @vol2

        @sender.find_candidates_to_sms.should_not include(@c1)
        @sender.find_candidates_to_sms.should include(@c2)
      end

      it "should only return candidates with SMS retries left" do
        @c1 = Candidate.make! mission: @mission, status: :pending,
          sms_retries: @organization.max_sms_retries
        @c2 = Candidate.make! mission: @mission, status: :pending,
          sms_retries: (@organization.max_sms_retries - 1)

        @sender.find_candidates_to_sms.should_not include(@c1)
        @sender.find_candidates_to_sms.should include(@c2)
      end

      it "should return non-readonly candidates" do
        @c1 = Candidate.make! mission: @mission, status: :pending

        @sender.find_candidates_to_sms.any?(&:readonly?).should be_false
      end

      it "should not return the same candidate twice if the volunteer has multiplie SMS numbers" do
        @c1 = Candidate.make! mission: @mission, volunteer: 
          (Volunteer.make! sms_channels: [SmsChannel.make, SmsChannel.make])

        @sender.find_candidates_to_sms.to_a.size.should eq(1)
      end
    end

    describe "send_sms_to_candidate" do
      before(:each) do
        @candidate = Candidate.make! mission: @mission, status: :pending
      end

      it "should send an SMS to all the SMS numbers of the volunteer"

      it "should set the last SMS attempt timestamp" do
        @sender.send_sms_to_candidate @candidate
        @candidate.reload
        @candidate.last_sms_att.should_not be_nil
        @candidate.last_sms_att.should eq(Time.now)
      end

      it "should increment SMS retries" do
        lambda do
          @sender.send_sms_to_candidate @candidate
          @candidate.reload
        end.should change(@candidate, :sms_retries).by(1)
      end
    end

    describe "next_deadline" do
      it "should return the earliest time to send the next SMS" do
        @time = Time.now
        @c1 = Candidate.make! mission: @mission, last_sms_att: @time
        @c2 = Candidate.make! mission: @mission, last_sms_att: @time.in(10.minutes)

        @deadline = @time + @organization.sms_timeout.minutes
        @sender.next_deadline.should >= @deadline
        @sender.next_deadline.should < @deadline + 1.minute
      end

      it "should ignore candidates who have no SMS numbers" do
        @time = Time.now
        @c1 = Candidate.make! mission: @mission, last_sms_att: @time, volunteer: (Volunteer.make! sms_channels: [])
        @c2 = Candidate.make! mission: @mission, last_sms_att: @time.in(10.minutes)

        @deadline = @time + (10 + @organization.sms_timeout).minutes
        @sender.next_deadline.should >= @deadline
        @sender.next_deadline.should < @deadline + 1.minute
      end

      it "should return now if no SMS has been sent" do
        @c1 = Candidate.make! mission: @mission

        @sender.next_deadline.should eq(Time.now)
      end

      it "should ignore candidates with no SMS retries left" do
        @c1 = Candidate.make! mission: @mission, sms_retries: @organization.max_sms_retries

        @sender.next_deadline.should be_nil
      end
    end
  end
end

