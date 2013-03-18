require 'spec_helper'

describe Volunteer do
  before(:each) do
    @volunteer = Volunteer.new
    @valid_attributes = {:name => "name", :lat => 10, :lng => 20, :address => "address", :sms_channels => [SmsChannel.make], :organization => Organization.make}
  end

  describe "availability" do
    it "should be available by default" do
      Day.all.each do |day|
        (0..23).each do |hour|
          @volunteer.available?(day, hour).should be true
        end
      end
    end

    it "should tell availability" do
      set_unavailable Day.tuesday, 10
      @volunteer.available?(Day.tuesday, 10).should be false
      set_available Day.tuesday, 10
      @volunteer.available?(Day.tuesday, 10).should be true
    end

    it "should tell availability by time" do
      time = Time.utc(2011,9,1,10,34,50)
      set_unavailable Day.thursday, 10
      @volunteer.available_at?(time).should be false
      set_available Day.thursday, 10
      @volunteer.available_at?(time).should be true
    end

    def set_available day, hour
      @volunteer.shifts = @volunteer.shifts || {}
      @volunteer.shifts[day.to_s] = @volunteer.shifts[day.to_s] || {}
      @volunteer.shifts[day.to_s][hour.to_s] = "1"
    end

    def set_unavailable day, hour
      @volunteer.shifts = @volunteer.shifts || {}
      @volunteer.shifts[day.to_s] = @volunteer.shifts[day.to_s] || {}
      @volunteer.shifts[day.to_s][hour.to_s] = "0"
    end
  end

  describe "valid" do
    it "should be valid with valid attributes" do
      @volunteer.attributes = @valid_attributes
      @volunteer.valid?.should be_true
    end

    it "should be invalid with no channels" do
      @volunteer.attributes = @valid_attributes.except(:sms_channels)
      @volunteer.valid?.should be_false
    end

    it "should be invalid without name" do
      @volunteer.attributes = @valid_attributes.except(:name)
      @volunteer.valid?.should be_false
    end

    it "should let volunteers with same name and different organization" do
      organization_a = Organization.make!
      organization_b = Organization.make!
      Volunteer.make! :name => 'foo', :organization => organization_a
      other_volunteer = Volunteer.make :name => 'foo', :organization => organization_b
      other_volunteer.should be_valid
    end
  end

  describe "skill names" do
    it "should assign skill names" do
      @volunteer.organization = Organization.make!
      @volunteer.skill_names = "one, two, three"

      skills = Skill.where(organization_id: @volunteer.organization_id)
      skills.map(&:name).sort.should eq(%w(one three two))
    end
  end

  describe "channels" do
    [[:sms_channels, :sms_numbers], [:voice_channels, :voice_numbers]].each do |type|
      channel = type[0]
      number = type[1]
      it "should build #{channel} when assigning #{number} as string" do
        @volunteer.send("#{number}=".to_sym, '1234,5678')
        @volunteer.send(channel).should have(2).items
        @volunteer.send(channel).first.volunteer.should eq(@volunteer)
        @volunteer.send(channel).first.address.should eq('1234')
        @volunteer.send(channel).second.volunteer.should eq(@volunteer)
        @volunteer.send(channel).second.address.should eq('5678')
      end

      it "should build #{channel} when assigning #{number} as array" do
        @volunteer.send("#{number}=".to_sym, ['1234','5678'])
        @volunteer.send(channel).should have(2).items
        @volunteer.send(channel).first.volunteer.should eq(@volunteer)
        @volunteer.send(channel).first.address.should eq('1234')
        @volunteer.send(channel).second.volunteer.should eq(@volunteer)
        @volunteer.send(channel).second.address.should eq('5678')
      end

      it "should tell error when bad #{number}" do
        @volunteer.attributes = @valid_attributes.except(:sms_channels, :voice_channels)
        @volunteer.send("#{number}=".to_sym, 'qwerty')
        @volunteer.valid?.should be_false
        @volunteer.should have(1).error_on(channel)
      end
    end
  end
end
