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
      @mission = Mission.make! :mission_skills => [MissionSkill.make(:skill => Skill.make!)]
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
      @mission.mission_skills[0].req_vols = @mission.mission_skills[0].req_vols + 1
      @mission.check_for_volunteers?.should be_true
    end

    it "should tell true if skill has changed" do
      @mission.mission_skills[0].skill = Skill.make!
      @mission.check_for_volunteers?.should be_true
    end

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

  describe "title" do
    before(:each) do
      @mission = Mission.new :name => "name", :reason => "reason",
        :mission_skills => [MissionSkill.make(:req_vols => 3, 
          :skill => Skill.new(:name => "skill"))] 
    end

    it "should tell title with all fields" do
      @mission.title.should eq("name: 3 skills (reason)")
    end

    it "should tell title without reason" do
      @mission.reason = nil
      @mission.title.should eq("name: 3 skills")
      @mission.reason = ''
      @mission.title.should eq("name: 3 skills")
    end

    it "should tell title with multiple required skills" do
      @mission.mission_skills << 
        MissionSkill.make(:mission => @mission, :req_vols => 1)

      @mission.title.should eq("name: 3 skills, 1 Volunteer (reason)") 
    end
  end

  it "should be invalid without name" do
    mission = Mission.make!
    mission.name = nil
    mission.valid?.should be_false
    mission.name = ''
    mission.valid?.should be_false
  end

  it "should limit the length of the description to 200 characters" do
    mission = Mission.make!
    mission.reason = 'a' * 200
    mission.valid?.should be_true
    mission.reason = 'a' * 201
    mission.valid?.should be_false
  end

	describe "messages" do
		before :each do
			@mission = Mission.new :address => "San Mateo"
		end

		[:sms_message, :voice_message].each do |kind|
			it "should tell #{kind.to_s} with reason" do
				@mission.reason = "a reason"
				@mission.send(kind).should eq(I18n.t(:template_message, :reason => "a reason", :location => "San Mateo") + I18n.t("#{kind.to_s}_options"))
			end

			it "should tell #{kind.to_s} without reason" do
			  @mission.send(kind).should eq(I18n.t(:template_message, :reason => "an emergency", :location => "San Mateo") + I18n.t("#{kind.to_s}_options"))
			end

			it "should use custom text if use custom text is enabled" do
  		  @mission.use_custom_text = true
  		  @mission.custom_text = "a custom text"
		    @mission.send(kind).should eq("a custom text." + I18n.t("#{kind.to_s}_options"))
  	  end
		end

		it "should tell voice message sentences" do
			@mission.expects(:voice_message).returns("First sentence. Second sentence . Third")
			@mission.voice_message_sentences.should eq(["First sentence", "Second sentence", "Third"])
		end

		it "should reject empty sentences in voice message" do
		  @mission.expects(:voice_message).returns("First sentence. . Third.\r\n")
		  @mission.voice_message_sentences.should eq(["First sentence", "Third"])
	  end
	end

	describe "enable/disable all" do
	  before(:each) do
	    @mission = Mission.new
  	  @candidates = 1.upto(3).map{|i|mock("candidate-#{i}")}
  	  @mission.expects(:pending_candidates).returns(@candidates)
    end

	  it "should enable all pending candidates" do
  	  @candidates.each{|c| c.expects(:enable!)}
  	  @mission.enable_all_pending
    end

    it "should disable all pending candidates" do
  	  @candidates.each{|c| c.expects(:disable!)}
  	  @mission.disable_all_pending
    end
  end

  describe "add_mission_skill" do
    it "should add one mission skill to the association" do
      @mission = Mission.new
      lambda do
        @mission.add_mission_skill
      end.should change(@mission.mission_skills, :size).by(1)
    end
  end

  describe "set candidates" do
    before(:each) do
      @mission = Mission.make!

      @vol1 = Volunteer.make!
      @vol2 = Volunteer.make!
      @vol3 = Volunteer.make!
    end

    it "should set a list of candidates for the given volunteers" do
      @mission.set_candidates [@vol1, @vol2]

      @mission.candidates.size.should eq(2)
      @mission.volunteers.should include(@vol1, @vol2)
    end

    it "should remove candidates not given in the new list" do
      @mission.set_candidates [@vol1, @vol2]
      @mission.set_candidates [@vol2, @vol3]
      
      @mission.candidates.size.should eq(2)
      @mission.volunteers.should include(@vol2, @vol3)
      @mission.volunteers.should_not include(@vol1)
    end

    it "should preserve the active status for existing volunteers" do
      @mission.set_candidates [@vol1, @vol2]
      @mission.candidates.where(:volunteer_id => @vol2.id).update_all(:active => false)

      @mission.candidates.where(:active => false).count.should eq(1)

      @mission.set_candidates [@vol2, @vol3]

      @mission.candidates.where(:active => false).map(&:volunteer).should include(@vol2)
    end
  end
end
