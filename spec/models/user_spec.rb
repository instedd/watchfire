require 'spec_helper'

describe User do
  it "is an owner" do
    user = User.make!
    organization = user.create_organization Organization.new(:name => 'RedCross')
    user.owner_of?(organization).should be_true
  end

  it "is not an owner" do
    user = User.make!
    organization = user.create_organization Organization.new(:name => 'RedCross')
    User.make!.owner_of?(organization).should be_false
  end

  it "joins a group on creation if it has been invited to it" do
    user = User.make!
    organization = user.create_organization Organization.new(:name => 'RedCross')

    user.invite_to(organization, 'foo@bar.com')

    user2 = User.make! email: 'foo@bar.com'
    user2.member_of?(organization).should be_true

    Invite.where(organization_id: organization.id, email: 'foo@bar.com').exists?.should be_false
  end
end
