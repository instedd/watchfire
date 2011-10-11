require 'spec_helper'

describe MissionsController do
  
  before(:all) do
    @user = User.make!
  end
  
  before(:each) do
    @mission = Mission.make! :user => @user
    sign_in @user
  end
  
  describe "show" do
    it "assigns mission" do
      get :show, :id => @mission.id.to_s
      assigns(:mission).should eq(@mission)
    end
  end
  
  describe "new" do
    it "renders show template with new mission" do
      get :new
      assigns(:mission).should be_new_record
      response.should render_template('show')
    end
  end
  
  describe "index" do
    it "should assign all missions that belong to the user" do
      get :index
      assigns(:missions).should eq([@mission])
    end
    
    it "should not return missions of other users" do
      other_user = User.make!
      other_mission = Mission.make! :user => other_user
      get :index
      assigns(:missions).should_not include other_mission
    end
  end
  
  describe "create" do
    before(:each) do
      @valid_attributes = {:req_vols => 5, :lat => 1, :lng => 2, :reason => 'foo', :address => 'bar', :name => 'name'}
    end
    
    it "should create mission" do
      expect {
        post :create, :mission => @valid_attributes
      }.to change(Mission, :count).by(1)
    end
    
    it "should check for volunteers" do
      mission = mock('mission')
      Mission.expects(:new).returns(mission)
      mission.expects(:check_and_save)
      mission.stubs(:user=)
      post :create, :mission => @valid_attributes
    end
    
    it "renders update" do
      post :create, :mission => @valid_attributes
      response.should render_template('update')
    end
    
    it "assigns mission to current user" do
      post :create, :mission => @valid_attributes
      Mission.last.user.should eq(@user)
    end
  end
  
  describe "update" do
    it "checks for volunteers if it's needed" do
      Mission.expects(:find).with(@mission.id.to_s).returns(@mission)
      @mission.expects(:check_for_volunteers?).returns(true)
      @mission.expects(:check_and_save)
      put :update, :id => @mission.id.to_s, :mission => {}, :format => 'js'
    end
    
    it "only saves if there is no need to check for volunteers" do
      Mission.expects(:find).with(@mission.id.to_s).returns(@mission)
      @mission.expects(:check_for_volunteers?).returns(false)
      @mission.expects(:save)
      put :update, :id => @mission.id.to_s, :mission => {}, :format => 'js'
    end
    
    it "assigns mission" do
      put :update, :id => @mission.id.to_s, :mission => {}, :format => 'js'
      assigns(:mission).should eq(@mission)
    end
    
    it "updates attributes" do
      Mission.any_instance.expects(:attributes=).with({'foo' => 'bar'})
      put :update, :id => @mission.id.to_s, :mission => {'foo' => 'bar'}, :format => 'js'
    end
  end

  describe "start" do
    it "should call volunteers" do
      Mission.expects(:find).with(@mission.id).returns(@mission)
      @mission.expects(:call_volunteers)
      post :start, :id => @mission.id, :format => 'js'
      assigns(:mission).should eq(@mission)
    end    
  end
  
  describe "stop" do
    it "should stop calling volunteers" do
      Mission.expects(:find).with(@mission.id).returns(@mission)
      @mission.expects(:stop_calling_volunteers)
      post :stop, :id => @mission.id, :format => 'js'
      assigns(:mission).should eq(@mission)
    end    
  end
  
  describe "refresh" do
    it "should assign mission" do
      get :refresh, :id => @mission.id.to_s
      assigns(:mission).should eq(@mission)
    end
    
    it "should render refresh with js" do
      get :refresh, :id => @mission.id.to_s, :format => 'js'
      response.should render_template('refresh')
    end
    
    it "should render show with html" do
      get :refresh, :id => @mission.id.to_s, :format => 'html'
      response.should render_template('show')
    end
  end
  
  describe "finish" do
    it "should finish mission" do
      Mission.expects(:find).with(@mission.id.to_s).returns(@mission)
      @mission.expects(:finish)
      post :finish, :id => @mission.id.to_s
      assigns(:mission).should eq(@mission)
      response.should render_template('show')
    end
  end
  
  describe "open" do
    it "should re open mission" do
      Mission.expects(:find).with(@mission.id.to_s).returns(@mission)
      @mission.expects(:open)
      post :open, :id => @mission.id.to_s
      assigns(:mission).should eq(@mission)
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
  
  describe "clone" do
    it "should create a mission duplicate" do
      new_mission = mock('new_mission')
      Mission.any_instance.expects(:new_duplicate).returns(new_mission)
      post :clone, :id => @mission.id.to_s
      assigns(:mission).should eq(new_mission)
    end
    
    it "renders show" do
      post :clone, :id => @mission.id.to_s
      response.should render_template('show')
    end
  end
	
	describe "export" do
		it "should export results" do
			Mission.expects(:find).with(@mission.id.to_s).returns(@mission)
			VolunteerExporter.expects(:export).with(@mission).returns("csv data")
			get :export, :id => @mission.id.to_s
			assigns(:mission).should eq(@mission)
			response.body.should eq("csv data")
		end
	end

end
