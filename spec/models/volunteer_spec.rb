require 'spec_helper'

describe Volunteer do
  before(:each) do
    @volunteer = Volunteer.new
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

  describe "skill names" do
    it "should assign skill names" do
      @volunteer.organization = Organization.make!
      @volunteer.skill_names = "one, two, three"

      skills = Skill.where(organization_id: @volunteer.organization_id)
      skills.map(&:name).sort.should eq(%w(one three two))
    end
  end
end
