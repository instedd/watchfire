class PigeonChannel < ActiveRecord::Base
  belongs_to :organization

  enum_attr :type, %w(^voice message)

  attr_accessible :description, :name, :pigeon_name, :type

  validates_presence_of :name
  validates_presence_of :pigeon_name
  validates_presence_of :type
end
