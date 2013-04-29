require "spec_helper"

describe Scheduler::OrganizationScheduler do
  before(:each) do
    EM.stubs(:add_timer)
    EM.stubs(:cancel_timer)

    @organization = Organization.make!
    @scheduler = Scheduler::OrganizationScheduler.new(@organization)
  end

  describe "next_sms_channel" do
    it "should return enabled channels with a round robin strategy" do
      @c1 = PigeonChannel.make!(:nuntium, organization: @organization)
      @c2 = PigeonChannel.make!(:nuntium, organization: @organization)
      @c3 = PigeonChannel.make!(:nuntium, organization: @organization, enabled: false)

      @scheduler.next_sms_channel.should eq(@c1)
      @scheduler.next_sms_channel.should eq(@c2)
      @scheduler.next_sms_channel.should eq(@c1)
    end
  end

  describe "next_voice_channel" do
    it "should return enabled channels" do
      @c1 = PigeonChannel.make!(:verboice, organization: @organization, enabled: false)
      @c2 = PigeonChannel.make!(:verboice, organization: @organization)

      @scheduler.next_voice_channel.should eq(@c2)
    end

    it "should return channels with slots available" do
      @c1 = PigeonChannel.make!(:verboice, organization: @organization, limit: 1)
      @c2 = PigeonChannel.make!(:verboice, organization: @organization)
      CurrentCall.make! pigeon_channel: @c1

      @scheduler.next_voice_channel.should eq(@c2)
    end
  end

  describe "call_status_update" do
    before(:each) do
      @call = CurrentCall.make!
    end

    %w(completed failed).each do |status|
      context "when status is #{status}" do
        it "should free the call slot" do
          lambda do
            @scheduler.call_status_update(@call.session_id, status)
          end.should change(CurrentCall, :count).by(-1)
        end

        it "should enqueue a try call" do
          @scheduler.expects(:schedule_try_call)
          @scheduler.call_status_update(@call.session_id, status)
        end
      end
    end

    context "when call is not finished" do
      it "should update call status" do
        @scheduler.call_status_update(@call.session_id, 'in-progress')
        @call.reload.call_status.should eq('in-progress')
      end
    end
  end

  describe "free_idle_call_slots" do
    it "should timeout and destroy calls that have been idle for #{Scheduler::OrganizationScheduler::CALL_TIMEOUT} seconds" do
      Timecop.freeze

      CurrentCall.make!
      Timecop.travel(2.minutes)
      CurrentCall.make!
      Timecop.travel(Scheduler::OrganizationScheduler::CALL_TIMEOUT - 1.minute)

      lambda do
        @scheduler.free_idle_call_slots
      end.should change(CurrentCall, :count).by(-1)
    end
  end

  describe "janitor" do
    it "should reload the organization" do
      @organization.expects(:reload)
      @scheduler.janitor
    end

    it "should free idle calls" do
      @scheduler.expects(:free_idle_call_slots)
      @scheduler.janitor
    end

    it "should enqueue a new try call" do
      @scheduler.expects(:schedule_try_call)
      @scheduler.janitor
    end

    it "should enqueue mission checks for all active missions" do
      @mission = Mission.make! :status => :running, organization: @organization

      @scheduler.expects(:schedule_mission_check).with(@mission.id)
      @scheduler.janitor
    end
  end

  describe "mission_check" do
    before(:each) do
      @mission = Mission.make! organization: @organization, status: :running
      @scheduler.expects(:find_active_mission).with(@mission.id).returns(@mission)
    end

    it "should check if mission is staffed or add more volunteers" do
      @mission.expects(:check_for_more_volunteers)
      @scheduler.mission_check(@mission.id)
    end

    it "should enqueue an unresponsive sweeper" do
      @scheduler.expects(:schedule_next_unresponsive_sweep).with(@mission)
      @scheduler.mission_check(@mission.id)
    end

    it "should enqueue a SMS send if the organization has SMS channels" do
      PigeonChannel.make!(:nuntium, organization: @organization)
      @scheduler.expects(:schedule_next_sms_send).with(@mission)
      @scheduler.mission_check(@mission.id)
    end

    it "should not enqueue a SMS send if the organization has no SMS channels" do
      @scheduler.expects(:schedule_next_sms_send).never
      @scheduler.mission_check(@mission.id)
    end
  end
end
