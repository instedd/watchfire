require 'spec_helper'

describe MissionSkill do
  before(:each) do
    @organization = Organization.make!
    @mission = Mission.make! :organization => @organization,
                             :lat => 0, :lng => 0
    @mission_skill = @mission.mission_skills[0]
    @skill = Skill.make! :organization => @organization
  end

  it "should begin with 1 volunteer to recruit" do
    @mission_skill.req_vols.should eq(1)
  end

  describe "title" do
    before(:each) do
      @skill.name = 'skill'
    end

    it "should tell title with singular value" do
      @mission_skill.req_vols = 1
      @mission_skill.skill = @skill

      @mission_skill.title.should eq('1 skill')
    end

    it "should tell title without skill" do
      @mission_skill.req_vols = 1

      @mission_skill.skill.should be_nil
      @mission_skill.title.should eq('1 Volunteer')
    end
  end

  describe "still needed" do
    before(:each) do
      @mission_skill.req_vols = 5
      @mission.save!

      @candidate = Candidate.make! mission: @mission
    end

    it "should return req_vols when there are no confirmed candidates" do
      @mission_skill.still_needed.should eq(@mission_skill.req_vols)
    end

    it "should subtract from req_vols when there are confirmed candidates allocated to the skill" do
      @candidate.allocated_skill = @mission_skill.skill
      @candidate.status = :confirmed
      @candidate.save!

      @mission_skill.still_needed.should eq(@mission_skill.req_vols - 1)
    end

    it "should not subtract from req_vols when the confirmed candidates have a different allocated skill" do
      @candidate.allocated_skill = @skill
      @candidate.status = :confirmed
      @candidate.save!

      @mission_skill.still_needed.should eq(@mission_skill.req_vols)
    end
  end
end
