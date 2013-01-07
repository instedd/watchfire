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

  include User::OrganizationConcern

  def display_name
    email
  end
end
