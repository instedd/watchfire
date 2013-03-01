class MissionSkill < ActiveRecord::Base
  belongs_to :mission
  belongs_to :skill

  validates_numericality_of :req_vols, :greater_than => 0
end
