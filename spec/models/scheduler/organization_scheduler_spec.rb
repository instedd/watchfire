require "spec_helper"

describe Scheduler::OrganizationScheduler do
   before(:each) do
     
   end

   describe "next_sms_channel" do
     it "should return enabled channels with a round robin strategy"
   end

   describe "next_voice_channel" do
     it "should return enabled channels"
     it "should return channels with slots available"
   end

   describe "call_status_update" do
     %w(completed failed).each do |status|
       context "when status is #{status}" do
         it "should free the call slot"
         it "should enqueue a try call"
       end
     end

     context "when call is not finished" do
       it "should update call status"
     end
   end

   describe "free_idle_call_slots" do
     it "should timeout and destroy calls that have been idle for #{Scheduler::OrganizationScheduler::CALL_TIMEOUT} seconds"
   end

   describe "janitor" do
     it "should reload the organization"
     it "should free idle calls"
     it "should enqueue a new try call"
     it "should enqueue mission checks for all active missions"
   end

   describe "mission_check" do
     it "should check if mission is staffed or add more volunteers"
     it "should enqueue an unresponsive sweeper"
     it "should enqueue a SMS send"
   end
end
