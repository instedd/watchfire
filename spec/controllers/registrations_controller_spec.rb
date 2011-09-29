require 'spec_helper'

describe Users::RegistrationsController do
  before :each do
    request.env['devise.mapping'] = Devise.mappings[:user]
  end
  
  describe "new" do
    it "should redirect to login" do
      get 'new'
      response.should redirect_to(new_user_session_path)
    end
  end
  
  describe "create" do
    it "should fail" do
      expect {
        post "create"
      }.to raise_error(ActionController::RoutingError)
    end
  end
  
  describe "destroy" do
    before :each do
      @user = User.make!
      sign_in @user
    end
    
    it "should fail" do
      expect {
        delete "destroy"
      }.to raise_error(ActionController::RoutingError)
    end
  end
end