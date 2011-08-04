class Mission < ActiveRecord::Base

  enum_attr :status, %w(^created running paused finished)

  has_many :candidates, :dependent => :destroy, , :include => :volunteer
  has_many :volunteers, :through => :candidates

  validates_presence_of :req_vols, :lat, :lng

  validates_numericality_of :req_vols, :only_integer => true, :greater_than => 0
  validates_numericality_of :lat, :less_than_or_equal_to => 90, :greater_than_or_equal_to => -90
  validates_numericality_of :lng, :less_than_or_equal_to => 180, :greater_than_or_equal_to => -180

end
