class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :invitable,
         :confirmable, :omniauthable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me

  has_many :members
  has_many :organizations, :through => :members
	has_many :missions
  has_many :identities, dependent: :destroy

  belongs_to :current_organization, :class_name => 'Organization'

  include User::OrganizationConcern

  def display_name
    email =~ /(.+)@/ && $1
  end
end
