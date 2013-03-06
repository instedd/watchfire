require 'spec_helper'

describe User do
  it "is an owner" do
    user = User.make!
    organization = user.create_organization Organization.make
    user.owner_of?(organization).should be_true
  end

  it "is not an owner" do
    user = User.make!
    organization = user.create_organization Organization.make
    User.make!.owner_of?(organization).should be_false
  end
end
