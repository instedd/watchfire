module User::OrganizationConcern
  extend ActiveSupport::Concern

  def has_organizations?
    organization_users.exists?
  end

  def owner_of?(organization)
    organization_users.where(organization_id: organization.id, role: :owner).exists?
  end

  def create_organization(organization)
    return unless organization.save

    make_default_organization_if_first(organization) do
      OrganizationUser.create! user_id: id, organization_id: organization.id, role: :owner
    end

    organization
  end

  def invite_to(organization, user_email)
    existing_user = User.find_by_email user_email
    if existing_user
      existing_user.join organization
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
end