require 'spec_helper'

describe OrganizationsController do
  let!(:user) { User.make! }

  before(:each) do
    sign_in user
  end

  describe "GET index" do
    it "is ok" do
      get :index
      response.should be_ok
    end
  end

  describe "POST create" do
    it "is creates an organization" do
      post :create, :organization => {:name => 'RedCross'}

      response.should redirect_to(organizations_path)

      organizations = user.organizations.all
      organizations.length.should eq(1)
      organizations.first.name.should eq('RedCross')

      organization_users = user.organization_users.all
      organization_users.length.should eq(1)
      organization_users.first.organization_id.should eq(organizations.first.id)
      organization_users.first.role.should eq(:owner)

      user.reload.current_organization_id.should eq(organizations.first.id)
    end
  end

  describe "PUT update" do
    it "is upates an organization" do
      organization = user.create_organization Organization.new(:name => 'RedCross')

      post :update, :id => organization.id, :organization => {:name => 'RedCross2'}

      response.should redirect_to(organization_path(organization))

      organization.reload.name.should eq('RedCross2')
    end
  end

  describe "GET select" do
    it "is selects an organization" do
      organization = user.create_organization Organization.new(:name => 'RedCross')

      get :select, :id => organization.id

      response.should redirect_to(missions_path)

      user.reload.current_organization_id.should eq(organization.id)
    end
  end
end
