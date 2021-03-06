require 'spec_helper'

describe MissionsController do
  before(:all) do
    @user = User.make!
    @organization = @user.create_organization Organization.make
  end

  after(:all) do
    @organization.destroy
    @user.destroy
  end

  before(:each) do
    @mission = Mission.make! :user => @user, :organization => @organization
    sign_in @user
    @mission_json = { "mission" => { "id" => 1, "name" => "foo" } }
  end

  describe "show" do
    it "assigns mission" do
      get :show, :id => @mission.id.to_s
      controller.mission.should eq(@mission)
    end
  end

  describe "new" do
    it "renders show template with new mission" do
      get :new
      controller.mission.should be_new_record
      response.should render_template('show')
    end
  end

  describe "index" do
    it "should assign all missions that belong to the user" do
      get :index
      controller.missions.should eq([@mission])
    end

    it "should not return missions of other users" do
      other_user = User.make!
      other_mission = Mission.make! :user => other_user
      get :index
      controller.missions.should_not include other_mission
    end
  end

  describe "create" do
    before(:each) do
      @valid_attributes = {:mission_skills_attributes => { '0' => {:req_vols => 5} }, :lat => 1, :lng => 2, :reason => 'foo', :address => 'bar', :name => 'name'}
    end

    it "should create mission" do
      expect {
        post :create, :mission => @valid_attributes
      }.to change(Mission, :count).by(1)
    end

    it "should create mission with one mission skill" do
      post :create, :mission => @valid_attributes
      Mission.last.mission_skills.size.should eq(1)
    end

    it "should check for volunteers" do
      mission = mock('mission')
      controller.stubs(:mission => mission)
      mission.expects(:check_and_save)
      controller.stubs(:mission_json)
      mission.stubs(:user=)
      mission.stubs(:organization=)
      post :create, :mission => @valid_attributes
    end

    it "renders mission json" do
      controller.expects(:mission_json).returns(@mission_json)
      post :create, :mission => @valid_attributes
      response.body.should eq(@mission_json.to_json)
    end

    it "assigns mission to current user" do
      post :create, :mission => @valid_attributes
      Mission.last.user.should eq(@user)
    end

    it "belongs to the current organization" do
      post :create, :mission => @valid_attributes
      Mission.last.organization.should eq(@organization)
    end
  end

  describe "update" do
    it "checks for volunteers if it's needed" do
      controller.stubs(:mission => @mission)
      @mission.expects(:check_for_volunteers?).returns(true)
      @mission.expects(:check_and_save)
      put :update, :id => @mission.id.to_s, :mission => {}
    end

    it "only saves if there is no need to check for volunteers" do
      controller.stubs(:mission => @mission)
      @mission.expects(:check_for_volunteers?).returns(false)
      @mission.expects(:save)
      put :update, :id => @mission.id.to_s, :mission => {}
    end

    it "assigns mission" do
      put :update, :id => @mission.id.to_s, :mission => {}
      controller.mission.should eq(@mission)
    end
  end

  describe "start" do
    it "should call volunteers" do
      controller.stubs(:mission => @mission)
      @mission.expects(:call_volunteers)
      post :start, :id => @mission.id
      controller.mission.should eq(@mission)
    end
  end

  describe "stop" do
    it "should stop calling volunteers" do
      controller.stubs(:mission => @mission)
      @mission.expects(:stop_calling_volunteers)
      post :stop, :id => @mission.id
      controller.mission.should eq(@mission)
    end
  end

  describe "finish" do
    it "should finish mission" do
      controller.stubs(:mission => @mission)
      @mission.expects(:finish)
      post :finish, :id => @mission.id.to_s
      controller.mission.should eq(@mission)
      response.should render_template('show')
    end
  end

  describe "open" do
    it "should re open mission" do
      controller.stubs(:mission => @mission)
      @mission.expects(:open)
      post :open, :id => @mission.id.to_s
      controller.mission.should eq(@mission)
      response.should render_template('show')
    end
  end

  describe "destroy" do
    it "should destroy mission" do
      delete :destroy, :id => @mission.id.to_s
      Mission.find_by_id(@mission.id).should be_nil
      response.should redirect_to(missions_url)
    end
  end

	describe "export" do
		it "should export results" do
      controller.stubs(:mission => @mission)
			VolunteerExporter.expects(:export).with(@mission).returns("csv data")
			get :export, :id => @mission.id.to_s
			controller.mission.should eq(@mission)
			response.body.should eq("csv data")
		end
	end

	describe "check_all" do
	  it "should enable all pending in mission" do
      controller.stubs(:mission => @mission)
	    @mission.expects(:enable_all_pending)
	    post :check_all, :id => @mission.id.to_s
    end

    it "renders mission json" do
      controller.stubs(:mission_json).returns(@mission_json)
      post :check_all, :id => @mission.id.to_s
      response.body.should eq(@mission_json.to_json)
    end
  end

  describe "uncheck_all" do
	  it "should disable all pending in mission" do
      controller.stubs(:mission => @mission)
	    @mission.expects(:disable_all_pending)
	    post :uncheck_all, :id => @mission.id.to_s
    end

    it "renders update_pending" do
      controller.stubs(:mission_json).returns(@mission_json)
      post :uncheck_all, :id => @mission.id.to_s
      response.body.should eq(@mission_json.to_json)
    end
  end
end
