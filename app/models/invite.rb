class Invite < ActiveRecord::Base
  belongs_to :organization

  validates_presence_of :email
end
