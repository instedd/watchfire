module User::OrganizationConcern
  extend ActiveSupport::Concern

  def has_organizations?
    members.exists?
  end

  def owner_of?(organization)
    members.where(organization_id: organization.id, role: :owner).exists?
  end

  def member_of?(organization)
    members.where(organization_id: organization.id).exists?
  end

  def create_organization(organization)
    return unless organization.save

    make_default_organization_if_first(organization) do
      Member.create! user_id: id, organization_id: organization.id, role: :owner
    end

    organization
  end

  def invite_to(organization, user_email)
    user_email = user_email.strip
    existing_user = User.find_by_email user_email
    if existing_user
      if existing_user.join organization
        :invited_existing
      else
        :already_member
      end
    else
      existing_invite = organization.invites.find_by_email user_email
      if existing_invite
        :already_invited
      else
        invite = organization.invites.create! email: user_email, token: Guid.new.to_s
        UserMailer.invite_to_organization(self, organization, user_email, invite.token).deliver
        :invited_new
      end
    end
  end

  def join(organization)
    return false if members.where(organization_id: organization.id).exists?

    make_default_organization_if_first(organization) do
      members.create! organization_id: organization.id, role: :member
    end
  end

  def make_default_organization_if_first(organization)
    had_organizations = has_organizations?

    result = yield

    unless had_organizations
      self.current_organization_id = organization.id
      self.save!
    end

    result
  end
end