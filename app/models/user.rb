class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :invitable,
         :confirmable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me

  has_many :organization_users
  has_many :organizations, :through => :organization_users
	has_many :missions

  belongs_to :current_organization, :class_name => 'Organization'

  def has_organizations?
    organization_users.exists?
  end

  def create_organization(organization)
    return unless organization.save

    had_organizations = has_organizations?

    OrganizationUser.create! user_id: id, organization_id: organization.id, role: 'owner'

    self.current_organization_id = organization.id unless had_organizations
    self.save!

    organization
  end
end
