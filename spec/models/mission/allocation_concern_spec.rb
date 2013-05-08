require 'spec_helper'

describe Mission::AllocationConcern do
  before(:each) do
    @organization = Organization.make!
    @skill1 = Skill.make! organization: @organization
    @skill2 = Skill.make! organization: @organization

    @origin = [37, -122] # lat, lng
    @mission = Mission.make! lat: @origin[0], lng: @origin[1], 
      organization: @organization

    @vol_at1 = make_volunteer @mission.endpoint(0,1), [@skill1, @skill2]
    @vol_outofrange = make_volunteer @mission.endpoint(0, 1000)
  end

  def make_volunteer location, skills = []
    Volunteer.make! lat: location.lat, lng: location.lng, 
      organization: @organization, skills: skills
  end

  describe "obtain volunteer pool" do
    before(:each) do
      @vol_at5 = make_volunteer @mission.endpoint(0,5)
      @vol_at2 = make_volunteer @mission.endpoint(0,2), [@skill1]
      @vol_at3 = make_volunteer @mission.endpoint(0,3), [@skill2]
    end

    context "when the mission requires only non-skilled volunteers" do
      it "should return only volunteers in range" do
        @mission.obtain_volunteer_pool.should_not include(@vol_outofrange)
      end

      it "should return volunteers ordered by distance to the mission" do
        @mission.obtain_volunteer_pool.should \
          eq([@vol_at1, @vol_at2, @vol_at3, @vol_at5])
      end
    end

    context "when the mission requires only skilled volunteers" do
      before(:each) do
        @ms = MissionSkill.make mission: @mission, skill: @skill1
        @mission.mission_skills = [@ms]
        @mission.save!
      end

      it "should return only volunteers with the skill for the mission" do
        @mission.obtain_volunteer_pool.should eq([@vol_at1, @vol_at2])
      end

      it "should return volunteers which have any of the skills required" do
        @mission.add_mission_skill skill: @skill2
        @mission.save!

        @mission.obtain_volunteer_pool.should eq([@vol_at1, @vol_at2, @vol_at3])
      end
    end

    context "when the mission requires skilled and non-skilled volunteers" do
      before(:each) do
        @mission.add_mission_skill skill: @skill2
        @mission.save!
      end

      it "should return all volunteers within range" do
        @mission.obtain_volunteer_pool.size.should eq(4)
      end
    end

    it "should not return rejected volunteers" do
      @mission.obtain_volunteer_pool([@vol_at1]).should_not include(@vol_at1)
    end

    it "should not return non-available volunteers" do
      # @time is Monday, April 22th 10:30:00 AM
      @time = Time.utc(2013, 4, 22, 10, 30, 0)
      @vol_at1.shifts = {'monday' => {'10' => '0'}}
      @vol_at1.save!

      Timecop.travel(@time)
      @mission.obtain_volunteer_pool.should_not include(@vol_at1)
    end
  end

  describe "initial allocation" do
    before(:each) do
      @vol_at5 = make_volunteer @mission.endpoint(0,5)
      @vol_at2 = make_volunteer @mission.endpoint(0,2), [@skill1]
      @vol_at3 = make_volunteer @mission.endpoint(0,3)
      @vol_at4 = make_volunteer @mission.endpoint(0,4)

      @mission.stubs(:available_ratio).returns(0.5)
    end

    it "should return a hash with skill ids as keys and volunteer lists as values" do
      allocation = @mission.initial_allocation
      allocation.should be_a(Hash)
      allocation.size.should eq(@mission.mission_skills.size)
      allocation.should include(nil)
      allocation[nil].should be_a(Array)
    end

    context "when the mission requires non-skilled volunteers" do
      it "should select the nearest required / available_ratio volunteers" do
        @mission.total_req_vols.should eq(1)

        allocation = @mission.initial_allocation
        allocation[nil].should eq([@vol_at1, @vol_at2])
      end

      it "should select all the volunteers even if there are not enough volunteers" do 
        @mission.mission_skills[0].req_vols = 5
        @mission.save!

        allocation = @mission.initial_allocation
        allocation.values.flatten.size.should eq(5)
      end
    end

    context "when the mission requires skilled volunteers" do
      before(:each) do
        @ms1 = @mission.add_mission_skill skill: @skill1
        @mission.save!
      end

      it "should select volunteers for the skill first" do
        @mission.total_req_vols.should eq(2)

        allocation = @mission.initial_allocation
        allocation.size.should eq(2)
        allocation.should include(nil)
        allocation.should include(@skill1.id)
        allocation[@skill1.id].should eq([@vol_at1, @vol_at2])
        allocation[nil].should eq([@vol_at3, @vol_at4])
      end

      it "should try to fulfill all requirements even if it doesn't have enough volunteers" do
        @mission.mission_skills[0].req_vols = 2
        @mission.mission_skills[1].req_vols = 2
        @mission.save!

        allocation = @mission.initial_allocation
        allocation[@skill1.id].size.should eq(2)
        allocation[nil].size.should eq(3)
      end

      it "should staff most risky skills first" do
        @ms2 = @mission.add_mission_skill skill: @skill2
        @mission.save!

        allocation = @mission.initial_allocation
        allocation.size.should eq(3)
        allocation[@skill2.id].should eq([@vol_at1])
        allocation[@skill1.id].should eq([@vol_at2])
        allocation[nil].should eq([@vol_at3, @vol_at4])
      end
    end

  end

  context "with initial allocation" do
    before(:each) do
      @vol_at5 = make_volunteer @mission.endpoint(0,5)
      @vol_at2 = make_volunteer @mission.endpoint(0,2), [@skill1]
      @vol_at3 = make_volunteer @mission.endpoint(0,3)
      @vol_at4 = make_volunteer @mission.endpoint(0,4), [@skill1]
      @vol_at6 = make_volunteer @mission.endpoint(0,6)
      @vol_at7 = make_volunteer @mission.endpoint(0,7), [@skill2]

      @mission.stubs(:available_ratio).returns(0.5)

      @mission.set_candidates [@vol_at1, @vol_at5]
    end

    describe "incremental allocation" do
      before(:each) do
        @mission.mission_skills[0].req_vols = 2
        @mission.save!
      end

      it "should return a hash with skill ids as keys" do
        allocation = @mission.incremental_allocation
        allocation.should be_a(Hash)
        allocation.size.should eq(@mission.mission_skills.size)
        allocation.should include(nil)
        allocation[nil].should be_a(Array)
      end

      it "should not select volunteers which are already in the mission" do
        allocation = @mission.incremental_allocation
        allocation.values.flatten.should_not include(@vol_at1)
        allocation.values.flatten.should_not include(@vol_at5)
        allocation.values.flatten.size.should > 0
      end

      it "should select more volunteers ordered by distance" do
        allocation = @mission.incremental_allocation
        allocation[nil].should eq([@vol_at2, @vol_at3])
      end

      it "should not select more volunteers if there are enough pending" do
        @mission.mission_skills[0].req_vols = 1
        @mission.save!

        @mission.incremental_allocation.values.flatten.should be_empty
      end
      
      context "when we add requirements for skilled volunteers" do
        before(:each) do
          @ms1 = @mission.add_mission_skill skill: @skill1
          @mission.save!
        end

        it "should reallocate previous volunteers if they have the skill" do
          allocation = @mission.incremental_allocation

          allocation[@skill1.id].size.should eq(1) # the other being @vol_at1
          allocation[@skill1.id].should eq([@vol_at2])
        end

        it "should allocate more volunteers for the rest of the requirements" do
          allocation = @mission.incremental_allocation

          allocation[nil].size.should eq(3)
          allocation[nil].should eq([@vol_at3, @vol_at4, @vol_at6])
        end
      end
    end

    describe "preferred skill for candidate" do
      before(:each) do
        @mission.add_mission_skill skill: @skill1
        @mission.save!
        # mission has two requirements:
        #  nil and @skill1, each needing 1 vol
        # and two pending candidates
        #  who can fulfill each requirement
      end

      it "should select the riskiest mission requirement" do
        candidate = @mission.candidates.find do |c|
          c.volunteer = @vol_at1
        end

        # skill specific requirements are always more risky than non-skilled
        @mission.preferred_skill_for_candidate(candidate).should eq(@skill1)
      end

      it "should select the riskiest mission requirement that the candidate can fulfill" do
        @mission.add_mission_skill skill: @skill2
        c7 = Candidate.make! mission: @mission, volunteer: @vol_at7

        # c7 has skill2 but not skill1
        @mission.preferred_skill_for_candidate(c7).should eq(@skill2)
      end

      it "should return nil if all requirements are fulfilled" do
        # confirm all mission's candidates fulfilling both requirements
        @mission.candidates.each do |c|
          c.status = :confirmed
          c.allocated_skill = case c.volunteer
                              when @vol_at1 then @skill1
                              else nil
                              end
          c.save!
        end

        # make a new candidate
        candidate = Candidate.make! mission: @mission, volunteer: @vol_at2

        @mission.preferred_skill_for_candidate(candidate).should be_nil
      end
    end
  end

  describe "pending allocation by risk" do
    it "should return mission skills ordered by risk" do
      @vol_at5 = make_volunteer @mission.endpoint(0,5)

      @mission.set_candidates [@vol_at1, @vol_at5]
      @mission.add_mission_skill skill: @skill1
      @mission.save!

      alloc = @mission.pending_allocation_by_risk
      alloc.should be_an(Array)
      alloc.size.should eq(2)
      alloc[0].should eq([@skill1.id, [@vol_at1]])
      alloc[1].should eq([nil, [@vol_at5]])
    end

    it "should allocate all pending volunteers, even if they are not needed" do
      @vol_at2 = make_volunteer @mission.endpoint(0,2)

      @mission.stubs(:available_ratio).returns(1)
      @mission.set_candidates [@vol_at1, @vol_at2]
      @mission.save!

      alloc = @mission.pending_allocation_by_risk
      alloc[0].should eq([nil, [@vol_at1, @vol_at2]])
    end
  end

  describe "check for more volunteers" do
    it "should add new pending candidates if required" do
      @mission.expects(:obtain_more_volunteers).returns([@vol_at1])
      @mission.expects(:add_volunteer).with(@vol_at1)

      @mission.check_for_more_volunteers
    end

    it "should finish the mission if all requirements are fulfilled" do
      candidate = Candidate.make! mission: @mission, volunteer: @vol_at1, status: :confirmed

      @mission.check_for_more_volunteers
      @mission.status.should eq(:finished)
    end

    it "should not finish the mission unless all requirements are fulfilled" do
      @mission.expects(:obtain_more_volunteers).returns([])
      @mission.check_for_more_volunteers

      @mission.status.should_not eq(:finished)
    end
  end
end

