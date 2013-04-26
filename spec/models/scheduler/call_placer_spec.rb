require 'spec_helper'

describe Scheduler::CallPlacer do
  before(:each) do
    @organization = Organization.make!
    @scheduler = Scheduler.new(@organization)
    @placer = Scheduler::CallPlacer(@scheduler)
  end

  describe "missions_by_latest_voice_attempt" do
    it "should return missions ordered by latest voice attempt"
    it "should only return active missions"
  end

  describe "find_next_volunteer_to_call" do
    it "should only return active pending candidates"
    it "should return candidates with voice numbers"
    it "should return candidates with voice retries left"
    it "should return candidates with expired voice timeout"  

    describe "candidates have multiple voice numbers" do
      it "when last number called is not the last voice number should not wait for timeout"
    end

    it "should return candidates for the riskiest skill first"
    it "should return nearest candidates first"
  end

  describe "place_call" do
    it "should enqueue a call with Verboice"
    it "should create a new current call"
    it "should set last voice attempt and last voice number"
    it "should increment voice retries if the number called is the last voice number of the volunteer"
  end

  describe "next_deadline" do
    it "should return nil if there are no voice channels"
    it "should only consider pending and active candidates"
    it "should only consider candidates with voice retries"
    it "should only consider running missions"
    it "should add voice timeout only if it called the last voice number"
  end
end

