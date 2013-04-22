class MissionSkill < ActiveRecord::Base
  include ActionView::Helpers::TextHelper

  belongs_to :mission
  belongs_to :skill

  validates_numericality_of :req_vols, :only_integer => true, :greater_than => 0

  after_initialize :init

  def check_for_volunteers?
    self.req_vols != self.req_vols_was || self.skill_id != self.skill_id_was
  end

  def title
    skill_name = skill.present? ? skill.name : 'Volunteer'
    pluralize(req_vols, skill_name)
  end

  def confirmed
    @confirmed ||= mission.candidates.
      where(:status => :confirmed).
      where(:allocated_skill_id => skill).count
  end

  def still_needed
    req_vols - confirmed
  end

  private

  def init
    self.req_vols ||= 1
  end
end
