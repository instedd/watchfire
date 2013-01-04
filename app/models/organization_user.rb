class OrganizationUser < ActiveRecord::Base
  belongs_to :organization
  belongs_to :user

  enum_attr :role, %w(^member owner)

  validates_presence_of :organization
  validates_presence_of :user
end
