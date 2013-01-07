module User::OrganizationConcern
  extend ActiveSupport::Concern

  included do
    after_create :join_organizations_if_invited
  end

  def has_organizations?
    organization_users.exists?
  end

  def owner_of?(organization)
    organization_users.where(organization_id: organization.id, role: :owner).exists?
  end

  def member_of?(organization)
    organization_users.where(organization_id: organization.id).exists?
  end

  def create_organization(organization)
    return unless organization.save

    make_default_organization_if_first(organization) do
      OrganizationUser.create! user_id: id, organization_id: organization.id, role: :owner
    end

    organization
  end

  def invite_to(organization, user_email)
    user_email = user_email.strip
    existing_user = User.find_by_email user_email
    if existing_user
      existing_user.join organization
      true
    else
      existing_invite = Invite.where(organization_id: organization.id, email: user_email).exists?
      unless existing_invite
        Invite.create!(organization_id: organization.id, email: user_email)
        UserMailer.invite_to_organization(self, organization, user_email).deliver
      end
      false
    end
  end

  def join(organization)
    return if organization_users.where(organization_id: organization.id).exists?

    make_default_organization_if_first(organization) do
      organization_users.create! organization_id: organization.id, role: :member
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

  def join_organizations_if_invited
    invites = Invite.where(email: email).includes(:organization).all
    invites.each do |invite|
      join invite.organization
    end
    invites.each &:destroy
  end
end