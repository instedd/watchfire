class Organization < ActiveRecord::Base
  has_many :organization_users
  has_many :users, :through => :organization_users
  has_many :volunteers
  has_many :missions

  validates_presence_of :name
end
