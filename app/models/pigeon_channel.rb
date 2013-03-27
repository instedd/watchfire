class PigeonChannel < ActiveRecord::Base
  belongs_to :organization

  enum_attr :channel_type, %w(^verboice nuntium)

  attr_accessible :description, :name

  validates_presence_of :organization, :name, :pigeon_name
  validates_presence_of :channel_type
end

