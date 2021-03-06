require 'spec_helper'

describe VolunteersController do

  # This should return the minimal set of attributes required to create a valid
  # Volunteer. As you add validations to Volunteer, be sure to
  # update the return value of this method accordingly.
  def valid_attributes
    {:organization_id => @organization.id, :name => 'John', :lat => -34.2, :lng => -58.2, :sms_numbers => '123', :voice_numbers => '456'}
  end

  before(:all) do
    @user = User.make!
    @organization = @user.create_organization Organization.make
  end

  after(:all) do
    @organization.destroy
    @user.destroy
  end

  before(:each) do
    sign_in @user
  end

  describe "GET index" do
    it "assigns all volunteers as @volunteers" do
      volunteer = Volunteer.create! valid_attributes
      get :index
      assigns(:volunteers).should eq([volunteer])
    end

    it "searches by voice or SMS number if the query string matches a phone number" do
      volunteer = Volunteer.create! valid_attributes
      get :index, :q => "123"
      assigns(:volunteers).should eq([volunteer])
    end
  end

  describe "GET new" do
    it "assigns the request volunteer as @volunteer" do
      volunteer = Volunteer.create! valid_attributes
      get :show, :id => volunteer.id.to_s
      controller.volunteer.should eq(volunteer)
    end
  end

  describe "GET new" do
    it "assigns a new volunteer as @volunteer" do
      get :new
      controller.volunteer.should be_a_new(Volunteer)
    end
  end

  describe "GET edit" do
    it "assigns the requested volunteer as @volunteer" do
      volunteer = Volunteer.create! valid_attributes
      get :edit, :id => volunteer.id.to_s
      controller.volunteer.should eq(volunteer)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Volunteer" do
        expect {
          post :create, :volunteer => valid_attributes
        }.to change(Volunteer, :count).by(1)
      end

      it "assigns a newly created volunteer as @volunteer" do
        post :create, :volunteer => valid_attributes
        controller.volunteer.should be_a(Volunteer)
        controller.volunteer.should be_persisted
      end

      it "redirects to the created volunteer" do
        post :create, :volunteer => valid_attributes
        response.should redirect_to(volunteers_url)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved volunteer as @volunteer" do
        # Trigger the behavior that occurs when invalid params are submitted
        Volunteer.any_instance.stubs(:save).returns(false)
        post :create, :volunteer => {}
        controller.volunteer.should be_a_new(Volunteer)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        Volunteer.any_instance.stubs(:save).returns(false)
        post :create, :volunteer => {}
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested volunteer" do
        volunteer = stub(:volunteer)
        controller.stubs(:volunteer => volunteer)
        volunteer.stubs(:id => 123)
        volunteer.expects(:update_attributes)
        volunteer.stubs(:name).returns('')
        put :update, :id => volunteer.id, :volunteer => {'these' => 'params'}
      end

      it "assigns the requested volunteer as @volunteer" do
        volunteer = Volunteer.create! valid_attributes
        put :update, :id => volunteer.id, :volunteer => valid_attributes
        controller.volunteer.should eq(volunteer)
      end

      it "redirects to the volunteer" do
        volunteer = Volunteer.create! valid_attributes
        put :update, :id => volunteer.id, :volunteer => valid_attributes
        response.should redirect_to(volunteers_url)
      end
    end

    describe "with invalid params" do
      it "assigns the volunteer as @volunteer" do
        volunteer = Volunteer.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Volunteer.any_instance.stubs(:save).returns(false)
        put :update, :id => volunteer.id.to_s, :volunteer => {}
        controller.volunteer.should eq(volunteer)
      end

      it "re-renders the 'edit' template" do
        volunteer = Volunteer.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Volunteer.any_instance.stubs(:save).returns(false)
        put :update, :id => volunteer.id.to_s, :volunteer => {}
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested volunteer" do
      volunteer = Volunteer.create! valid_attributes
      expect {
        delete :destroy, :id => volunteer.id.to_s
      }.to change(Volunteer, :count).by(-1)
    end

    it "redirects to the volunteers list" do
      volunteer = Volunteer.create! valid_attributes
      delete :destroy, :id => volunteer.id.to_s
      response.should redirect_to(volunteers_url)
    end
  end

  describe "POST confirm_import" do
    it "accepts an empty volunteer list" do
      post :confirm_import
      response.should redirect_to(volunteers_path)
    end
  end

end
