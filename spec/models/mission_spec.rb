require 'spec_helper'

describe Mission do

  it "should call volunteers" do
    mission = Mission.new
    mission.stubs(:save!).returns(true)
    
    c1 = mock('c1')
    c2 = mock('c2')
    
    mission.expects(:candidates_to_call).returns([c2])
		mission.expects(:pending_candidates).never

		c1.stubs(:paused).returns(true)
    
    c1.expects(:call).never
    c2.expects(:call)
    
    mission.call_volunteers
    
    mission.is_running?.should be true
  end
  
  %w(pending confirmed).each do |status|
    it "should tell #{status} candidates" do
      mission = Mission.make!
      c1 = Candidate.make! :mission => mission, :status => status.to_sym
      c2 = Candidate.make! :mission => mission, :status => :unresponsive
      c3 = Candidate.make! :mission => mission, :status => status.to_sym
    
      volunteers = mission.send "#{status}_candidates"
    
      volunteers.length.should == 2
      volunteers.should include c1
      volunteers.should include c3
    end
  end
  
  describe "stop calling volunteers" do
    before(:each) do
      @mission = Mission.make! :status => :running
    end
    
    it "should change status to paused" do
      @mission.stop_calling_volunteers
      @mission.reload.is_paused?.should be true
    end
    
    it "should destroy any mission jobs" do
      (1..3).each{ MissionJob.make! :mission => @mission }
      @mission.should have(3).mission_jobs
      @mission.stop_calling_volunteers
      @mission.should have(0).mission_jobs
    end
  end
  
  describe "finish" do
    before(:each) do
      @mission = Mission.make! :status => :running
    end
    
    it "should change status to finished" do
      @mission.finish
      @mission.reload.finished?.should be true
    end
    
    it "should destroy any mission jobs" do
      (1..3).each{ MissionJob.make! :mission => @mission }
      @mission.should have(3).mission_jobs
      @mission.finish
      @mission.should have(0).mission_jobs
    end 
  end
  
  it "should set status to paused if opening" do
    mission = Mission.make!
    mission.paused?.should be false
    mission.open
    mission.reload.paused?.should be true
  end
  
  it "should add a volunteer" do
    mission = Mission.make!
    mission.candidates.length.should == 0
    volunteer = Volunteer.make!
    mission.add_volunteer volunteer
    mission.candidates.length.should == 1
    mission.candidates.first.volunteer.should == volunteer
  end
  
  describe "check for volunteers" do
    before(:each) do
      @mission = Mission.make! :skill => Skill.make!
    end
    
    it "should tell true if lat has changed" do
      @mission.lat = @mission.lat + 1
      @mission.check_for_volunteers?.should be_true
    end
    
    it "should tell true if lng has changed" do
      @mission.lng = @mission.lng + 1
      @mission.check_for_volunteers?.should be_true
    end
    
    it "should tell true if required volunteers has changed" do
      @mission.req_vols = @mission.req_vols + 1
      @mission.check_for_volunteers?.should be_true
    end
    
    it "should tell true if skill has changed" do
      @mission.skill = Skill.make!
      @mission.check_for_volunteers?.should be_true
    end
    
  end
  
  describe "get more volunteers" do
    before(:each) do
      @mission = Mission.new :name => 'name'
      @mission.stubs(:available_ratio).returns(0.5)
    end
    
    it "should increase volunteers if pending is not enough" do
      @mission.req_vols = 5
			@mission.lat = 10.0
			@mission.lng = 10.0
      @mission.expects(:pending_candidates).returns((1..8).to_a)
      @mission.expects(:confirmed_candidates).returns([])

			candidates = (1..10).to_a
			candidates.expects :reload
      @mission.expects(:candidates).twice.returns(candidates)
      
      @mission.expects(:obtain_volunteers).with(2,10).returns(['c1','c2'])
      
      @mission.expects(:add_volunteer).with('c1')
      @mission.expects(:add_volunteer).with('c2')
      
      @mission.check_for_more_volunteers
    end
    
    it "should not increase volunteers if there are enough pendings and set as finished" do
      @mission.req_vols = 5
			@mission.lat = 10.0
			@mission.lng = 10.0
      @mission.expects(:pending_candidates).returns((1..8).to_a)
      @mission.expects(:confirmed_candidates).returns((1..2).to_a)
      
      @mission.expects(:obtain_volunteers).never
      @mission.expects(:add_volunteer).never
      
      @mission.check_for_more_volunteers
    end
    
  end
  
  describe "obtain volunteers" do
    before(:each) do
      @time = Time.utc(2011, 9, 1, 10, 30, 0)
      @mission = Mission.make! :lat => 0, :lng => 0
      
      @s1 = Skill.make!
      @s2 = Skill.make!
      
      @v1 = Volunteer.make :lat => 0.5, :lng => 0.5

      @v1.skills << @s1
      @v1.save!
      
      @v2 = Volunteer.make :lat => 1, :lng => 1
      @v2.skills = [@s1, @s2]
      @v2.save!
      
      @v3 = Volunteer.make! :lat => 2, :lng => 2
    end
    
    it "should not filter by skill if skill is not selected" do
      @mission.skill.should be nil
      volunteers = @mission.obtain_volunteers 3
      volunteers.should == [@v1, @v2, @v3]
    end
    
    it "should filter by skill" do
      @mission.skill = @s1
      @mission.save!
      
      volunteers = @mission.obtain_volunteers 3
      volunteers.should == [@v1, @v2]
    end
    
    it "should filter by shift" do
      @v1.shifts = {'thursday' => {"10" => "1"}}
      @v1.save!
      @v2.shifts = {"thursday" => {"10" => "0"}}
      @v2.save!
      @v3.shifts = {"thursday" => {"10" => "1"}}
      @v3.save!
      
      Timecop.travel(@time)
      volunteers = @mission.obtain_volunteers 3
      volunteers.should == [@v1, @v3]
    end
    
    it "should filter by max distance" do
      @mission.expects(:max_distance).returns(200)
      v4 = Volunteer.make! :lat => 3, :lng => 3
      volunteers = @mission.obtain_volunteers 4
      volunteers.should == [@v1, @v2, @v3]
    end
  end
  
  it "should begin with 1 volunteer to recruit" do
    mission = Mission.new
    mission.req_vols.should eq(1)
  end
  
  describe "title" do
    before(:each) do
      @mission = Mission.new :name => "name", :req_vols => 3, :skill => Skill.new(:name => "skill"), :reason => "reason"
    end
    
    it "should tell title with all fields" do
      @mission.title.should eq("name: 3 skills (reason)")
    end
    
    it "should tell title with singular value" do
      @mission.req_vols = 1
      @mission.title.should eq("name: 1 skill (reason)")
    end
    
    it "should tell title without reason" do
      @mission.reason = nil
      @mission.title.should eq("name: 3 skills")
      @mission.reason = ''
      @mission.title.should eq("name: 3 skills")
    end
    
    it "should tell title without skill" do
      @mission.skill = nil
      @mission.title.should eq("name: 3 Volunteers (reason)")
    end
  end
  
  it "should be invalid without name" do
    mission = Mission.make!
    mission.name = nil
    mission.valid?.should be_false
    mission.name = ''
    mission.valid?.should be_false
  end
  
  describe "mission duplicate for new skill recruitment" do
    before(:each) do
      @mission = Mission.make! :skill => Skill.make!
      @new_mission = @mission.new_duplicate
    end
    
    it "creates an unsaved mission" do
      @new_mission.new_record?.should be_true
    end
    
    it "copies values" do
      @new_mission.name.should eq(@mission.name)
      @new_mission.req_vols.should eq(@mission.req_vols)
      @new_mission.reason.should eq(@mission.reason)
      @new_mission.lat.should eq(@mission.lat)
      @new_mission.lng.should eq(@mission.lng)
      @new_mission.address.should eq(@mission.address)
      @new_mission.skill.should eq(@mission.skill)
    end
    
    it "should have created status" do
      @new_mission.created?.should be_true
    end
    
  end
  
end
