require 'spec_helper'

describe MissionSkill do
  def make_volunteer(lat, lng, skills = [])
    Volunteer.make! :organization => @organization, 
                    :lat => lat, :lng => lng, :skills => skills
  end

  before(:each) do
    @organization = Organization.make!
    @mission = Mission.make! :organization => @organization,
                             :lat => 0, :lng => 0
    @mission_skill = MissionSkill.make! :mission => @mission
    @skill = Skill.make! :organization => @organization
  end

  describe "obtain_volunteers" do
    before(:each) do
      # mission is at (0,0)
      # each degree in longitude is about 69 miles
      @volunteer_1 = make_volunteer 0, 0.5
      @volunteer_2 = make_volunteer 0, 1, [@skill]
      @volunteer_3 = make_volunteer 0, 1.5
      @volunteer_4 = make_volunteer 0, 2, [@skill]
      @volunteer_5 = make_volunteer 0, 3

      # 200 mile range, so @vol5 is slightly out of range
      @mission.stubs(:max_distance).returns(200)
    end

    it "finds all volunteers within range" do
      found_volunteers = @mission_skill.obtain_volunteers 10

      found_volunteers.size.should eq(4)
      found_volunteers.should eq([@volunteer_1, @volunteer_2, 
                                  @volunteer_3, @volunteer_4])
    end

    it "restricts returned volunteers by quantity" do
      found_volunteers = @mission_skill.obtain_volunteers 2

      found_volunteers.size.should eq(2)
      found_volunteers.should eq([@volunteer_1, @volunteer_2])
    end

    it "finds volunteers with specific skill" do
      @mission_skill.skill = @skill
      found_volunteers = @mission_skill.obtain_volunteers 10

      found_volunteers.size.should eq(2)
      found_volunteers.should eq([@volunteer_2, @volunteer_4])
    end

    it "given a set of forbidden volunteers, finds others" do
      @mission_skill.skill = @skill
      found_volunteers = @mission_skill.obtain_volunteers 2, 
        [@volunteer_1, @volunteer_2]

      found_volunteers.size.should eq(1)
      found_volunteers.should eq([@volunteer_4])
    end
  end

  describe "claim_candidates" do
    def make_candidate skills = []
      Candidate.make! :mission => @mission, 
                      :volunteer => make_volunteer(0, 0, skills)
    end

    before(:each) do
      @candidates = []
      @candidates << make_candidate
      @candidates << make_candidate([@skill])
      @candidates << make_candidate
      @candidates << make_candidate([@skill])
    end

    it "with no skill required" do
      @mission_skill.req_vols = 2
      claims = @mission_skill.claim_candidates @candidates
      claims.should eq(@candidates.take(2))

      claims = @mission_skill.claim_candidates @candidates, 10
      claims.should eq(@candidates)
    end

    it "with a skill required" do
      @mission_skill.req_vols = 1
      @mission_skill.skill = @skill

      claims = @mission_skill.claim_candidates @candidates
      claims.should eq([@candidates[1]])

      claims = @mission_skill.claim_candidates @candidates, 4
      claims.should eq([@candidates[1], @candidates[3]])
    end
  end
end
