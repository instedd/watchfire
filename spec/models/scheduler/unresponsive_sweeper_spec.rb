require 'spec_helper'

module Scheduler
  describe UnresponsiveSweeper do
    describe "unresponsive_candidates" do
      it "should return pending candidates with no retries and expired timeouts"
      it "should not return candidates with SMS numbers and SMS retries left"
      it "should not return candidates with voice numbers and voice retries left"
      it "should not return candidates with no retries but no expired timeouts"
    end
  end
end

