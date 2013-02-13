class Organization < ActiveRecord::Base
  has_many :members
  has_many :users, :through => :members
  has_many :volunteers
  has_many :missions
  has_many :skills
  has_many :invites

  validates_presence_of :name
end
