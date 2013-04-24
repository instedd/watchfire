require 'spec_helper'

module Scheduler
  describe SmsSender do
    before(:each) do
      @mission = Mission.make!
    end

    describe "find_candidates_to_sms" do
      it "should return pending candidates"
      it "should return candidates who we never sent an SMS to"
      it "should return candidates with expired SMS timeout"
      it "should only return candidates that have SMS numbers"
      it "should only return candidates with SMS retries left"
    end

    describe "send_sms_to_candidate" do
      it "should send an SMS to all the SMS numbers of the volunteer"
      it "should set the last SMS attempt timestamp"
      it "should increment SMS retries"
    end

    describe "calculate_next_time" do
      it "should return the earliest time to send the next SMS"
      it "should ignore candidates who have no SMS numbers"
    end
  end
end

