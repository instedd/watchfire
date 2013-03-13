require 'spec_helper'

describe User::OrganizationConcern do
  before(:each) do
    @user = User.make!
    @organization = Organization.make
    @user.create_organization(@organization)
  end

  describe "invite_to" do
    it "rejects blank email" do
      @user.invite_to(@organization, '').should be(:invalid_email)
    end

    it "rejects invalid email" do
      @user.invite_to(@organization, '123').should be(:invalid_email)
    end

    it "does not create invite on mail delivery failed" do
      mail = mock()
      UserMailer.expects(:invite_to_organization).returns(mail)
      mail.expects(:deliver).raises()
      lambda do
        @user.invite_to(@organization, 'foo@bar.com').should be(:delivery_error)
      end.should_not change(Invite, :count)
    end
  end

end
