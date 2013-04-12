require 'spec_helper'

describe PigeonChannel do
  describe "missions" do
    before(:each) do
      @mission = Mission.make
    end

    [:nuntium, :verboice].each do |type|
      it "returns missions that link to the channel as a #{type} channel" do
        @channel = PigeonChannel.make! :channel_type => type, :organization => @mission.organization
        @mission.send("#{type}_channel=", @channel)
        @mission.save!

        @channel.missions.should include(@mission)
      end
    end
  end

  describe "destruction" do
    before(:each) do
      @organization = Organization.make!
      @channel = PigeonChannel.make! :channel_type => :verboice, :organization => @organization
      @mission = Mission.make! organization: @organization, verboice_channel: @channel
    end

    it "should prevent being destroyed if it has running missions" do
      @mission.update_attribute :status, :running

      @channel.destroy
      @channel.should_not be_destroyed
      @channel.errors.should_not be_empty
    end

    it "should unlink from missions before being destroyed" do
      @channel.destroy

      @channel.should be_destroyed
      @mission.reload
      @mission.verboice_channel.should be_nil
    end
  end
end
