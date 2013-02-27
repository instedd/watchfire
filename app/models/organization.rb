class Organization < ActiveRecord::Base
  has_many :members
  has_many :users, :through => :members
  has_many :volunteers
  has_many :missions
  has_many :skills
  has_many :invites

  validates_presence_of :name

  validates_numericality_of :max_sms_retries, :only_integer => true, :greater_than_or_equal_to => 1
  validates_numericality_of :max_voice_retries, :only_integer => true, :greater_than_or_equal_to => 1
  validates_numericality_of :sms_timeout, :only_integer => true, :greater_than_or_equal_to => 0
  validates_numericality_of :voice_timeout, :only_integer => true, :greater_than_or_equal_to => 0
end
