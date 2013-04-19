require 'spec_helper'

describe Mission::AllocationConcern do
  before(:each) do
    @organization = Organization.make!
  end

  it "should obtain volunteers for each skill" do
    @mission = Mission.make
    @ms1 = MissionSkill.make :mission => @mission, :req_vols => 5
    @ms2 = MissionSkill.make :mission => @mission, :req_vols => 10
    @mission.mission_skills = [@ms1, @ms2]
    @mission.save!

    @mission.stubs(:available_ratio).returns(0.5)
    @ms1.expects(:obtain_volunteers).with(10, []).returns((1..5).to_a)
    @ms2.expects(:obtain_volunteers).with(20, (1..5).to_a).returns((6..10).to_a)

    vols = @mission.obtain_volunteers
    vols.size.should eq(10)
    vols.should eq((1..10).to_a)
  end

  describe "candidate allocation" do
    before(:each) do
      @mission = Mission.make!
      @mission.stubs(:available_ratio).returns(0.5)
    end

    it "should allocate by priority" do
      @ms1 = MissionSkill.make!(:mission => @mission, :priority => 2, :req_vols => 3)
      @ms2 = MissionSkill.make!(:mission => @mission, :priority => 1, :req_vols => 2)
      @ms3 = MissionSkill.make!(:mission => @mission, :priority => 3, :req_vols => 2)
      @mission.mission_skills = [@ms1, @ms2, @ms3]
      @mission.save!

      @candidates = (1..3).map { Candidate.make! }
      @pendings = (1..2).map { Candidate.make! }

      allocation = @mission.allocate_candidates(@candidates, @pendings)

      allocation.size.should eq(3)
      allocation[0][:mission_skill].should eq(@ms2)
      allocation[0][:needed].should eq(0)
      allocation[0][:confirmed].should eq(@candidates[0..1])
      allocation[0][:pending].should eq([])
      allocation[1][:mission_skill].should eq(@ms1)
      allocation[1][:needed].should eq(4)  # 2 missing * available_ratio
      allocation[1][:confirmed].should eq(@candidates[2..2])
      allocation[1][:pending].should eq(@pendings)
      allocation[2][:mission_skill].should eq(@ms3)
      allocation[2][:needed].should eq(4)    # 2 missing * available_ratio
      allocation[2][:confirmed].should eq([])
      allocation[2][:pending].should eq([])  # no pending candidates left
    end
  end

  describe "get more volunteers" do
    before(:each) do
      @mission = Mission.make! :name => 'name'
      @mission_skill = MissionSkill.make!(:mission => @mission, :req_vols => 5)
      @mission.mission_skills = [@mission_skill]
      @mission.save!
    end

    it "should increase volunteers if pending is not enough" do
      @mission.expects(:pending_candidates).returns((1..8).to_a)
      @mission.expects(:confirmed_candidates).returns([])
      @mission.stubs(:candidate_allocation_order).
        returns(Proc.new { |c1,c2| c1 <=> c2 })
      allocation = [{
        :mission_skill => @mission_skill,
        :confirmed => [],
        :pending => (1..8).to_a,
        :needed => 10
      }]
      @mission.expects(:allocate_candidates).returns(allocation)

      @mission_skill.expects(:obtain_volunteers).
        with(2, @mission.volunteers).returns(['c1', 'c2'])
      @mission.expects(:add_volunteer).with('c1')
      @mission.expects(:add_volunteer).with('c2')

      @mission.expects(:update_status).never

      @mission.check_for_more_volunteers
    end

    it "should not increase volunteers if there are enough pendings and set as finished" do
      @mission.expects(:pending_candidates).returns((1..8).to_a)
      @mission.expects(:confirmed_candidates).returns((1..2).to_a)
      @mission.stubs(:candidate_allocation_order).
        returns(Proc.new { |c1,c2| c1 <=> c2 })
      allocation = [{
        :mission_skill => @mission_skill,
        :confirmed => (1..2).to_a,
        :pending => (1..8).to_a,
        :needed => 6
      }]
      @mission.expects(:allocate_candidates).returns(allocation)
      @mission.expects(:update_status).never

      @mission.check_for_more_volunteers
    end

    it "should update status to finished if all requirements are satisfied" do
      @mission.expects(:pending_candidates).returns([])
      @mission.expects(:confirmed_candidates).returns((1..5).to_a)
      @mission.stubs(:candidate_allocation_order).
        returns(Proc.new { |c1,c2| c1 <=> c2 })
      allocation = [{
        :mission_skill => @mission_skill,
        :confirmed => (1..5).to_a,
        :pending => [],
        :needed => 0
      }]
      @mission.expects(:allocate_candidates).returns(allocation)
      @mission.expects(:update_status).with(:finished)

      @mission.check_for_more_volunteers
    end

  end

  def make_volunteer location, skills = []
    Volunteer.make! lat: location.lat, lng: location.lng, 
      organization: @organization, skills: skills
  end

  describe "obtain volunteer pool" do
    before(:each) do
      @origin = [37, -122] # lat, lng
      @mission = Mission.make! lat: @origin[0], lng: @origin[1], 
        organization: @organization

      @skill1 = Skill.make! organization: @organization
      @skill2 = Skill.make! organization: @organization

      @vol_at5 = make_volunteer @mission.endpoint(0,5)
      @vol_at2 = make_volunteer @mission.endpoint(0,2), [@skill1]
      @vol_at3 = make_volunteer @mission.endpoint(0,3), [@skill2]
      @vol_at1 = make_volunteer @mission.endpoint(0,1), [@skill1, @skill2]
      @vol_outofrange = make_volunteer @mission.endpoint(0, 1000)
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
  end

  describe "initial allocation" do
    before(:each) do
      @origin = [37, -122] # lat, lng
      @mission = Mission.make! lat: @origin[0], lng: @origin[1], 
        organization: @organization

      @skill1 = Skill.make! organization: @organization
      @skill2 = Skill.make! organization: @organization

      @vol_at5 = make_volunteer @mission.endpoint(0,5)
      @vol_at2 = make_volunteer @mission.endpoint(0,2), [@skill1]
      @vol_at3 = make_volunteer @mission.endpoint(0,3)
      @vol_at1 = make_volunteer @mission.endpoint(0,1), [@skill1, @skill2]
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

  describe "incremental allocation" do
    before(:each) do
      @origin = [37, -122] # lat, lng
      @mission = Mission.make! lat: @origin[0], lng: @origin[1], 
        organization: @organization

      @skill1 = Skill.make! organization: @organization
      @skill2 = Skill.make! organization: @organization

      @vol_at5 = make_volunteer @mission.endpoint(0,5)
      @vol_at2 = make_volunteer @mission.endpoint(0,2), [@skill1]
      @vol_at3 = make_volunteer @mission.endpoint(0,3)
      @vol_at1 = make_volunteer @mission.endpoint(0,1), [@skill1, @skill2]
      @vol_at4 = make_volunteer @mission.endpoint(0,4), [@skill1]
      @vol_at6 = make_volunteer @mission.endpoint(0,6)
      @vol_at7 = make_volunteer @mission.endpoint(0,7), [@skill2]

      @mission.stubs(:available_ratio).returns(0.5)

      allocation = @mission.initial_allocation
      @mission.set_candidates [@vol_at1, @vol_at5]
    end

    it "should return a hash with skill ids as keys" do
      allocation = @mission.incremental_allocation
      allocation.should be_a(Hash)
      allocation.size.should eq(@mission.mission_skills.size)
      allocation.should include(nil)
      allocation[nil].should be_a(Array)
    end

    it "should not select volunteers which are already in the mission" do
      @mission.mission_skills[0].req_vols = 2
      @mission.save!

      allocation = @mission.incremental_allocation
      allocation.values.flatten.should_not include(@vol_at1)
      allocation.values.flatten.should_not include(@vol_at5)
      allocation[nil].should eq([@vol_at2, @vol_at3])
    end

    it "should select more volunteers ordered by distance"
    
    context "when we add requirements for skilled volunteers" do
      before(:each) do
        @ms1 = @mission.add_mission_skill skill: @skill1
        @mission.save!
      end

      it "should reallocate previous volunteers if they have the skill"
      it "should allocate more volunteers for the rest of the requirements"
    end
  end
end

