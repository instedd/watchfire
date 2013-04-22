class Organization < ActiveRecord::Base
  has_many :members, :dependent => :destroy
  has_many :users, :through => :members
  has_many :volunteers, :dependent => :destroy
  has_many :missions, :dependent => :destroy
  has_many :skills, :dependent => :destroy
  has_many :invites, :dependent => :destroy
  has_many :pigeon_channels, :dependent => :destroy

  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false

  validates_numericality_of :max_sms_retries, :only_integer => true, :greater_than_or_equal_to => 1, :less_than_or_equal_to => 20
  validates_numericality_of :max_voice_retries, :only_integer => true, :greater_than_or_equal_to => 1, :less_than_or_equal_to => 20
  validates_numericality_of :sms_timeout, :only_integer => true, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 120
  validates_numericality_of :voice_timeout, :only_integer => true, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 120
end
