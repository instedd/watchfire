require 'spec_helper'

describe MembersController do
  render_views

  let!(:user) { User.make! }
  let!(:organization) { user.create_organization Organization.make }

  before(:each) do
    sign_in user
  end

  describe "GET index" do
    it "is ok" do
      get :index
      response.should be_ok
    end
  end

  describe "POST invite" do
    it "invites an existing user" do
      user2 = User.make!

      post :invite, :email => user2.email

      response.should redirect_to(members_path)

      member = user2.members.where(:organization_id => organization.id).first
      member.should_not be_nil
      member.role.should eq(:member)

      user2.reload.current_organization_id.should eq(organization.id)
    end

    it "invites a new user" do
      post :invite, :email => 'foo@bar.com'

      response.should redirect_to(members_path)

      invites = Invite.where(organization_id: organization.id).all
      invites.length.should eq(1)
      invites.first.token.should_not be_nil
    end

    it "rejects blank email" do
      lambda do
        post :invite
        response.should redirect_to(members_path)
      end.should_not change {
        Invite.where(organization_id: organization.id).all.size
      }
    end

    it "rejects an invalid email" do
      lambda do
        post :invite, :email => '123'
        response.should redirect_to(members_path)
      end.should_not change {
        Invite.where(organization_id: organization.id).all.size
      }
    end
  end

  describe "GET accept invite" do
    it "accepts an invite" do
      user2 = User.make!

      organization.invites.create! token: '1234', email: 'foo@bar.com'

      sign_in user2
      get :accept_invite, token: '1234'

      response.should redirect_to(missions_path)

      Invite.count.should eq(0)

      user2.reload.current_organization_id.should eq(organization.id)
    end
  end
end
