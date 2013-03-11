class MissionSkill < ActiveRecord::Base
  include ActionView::Helpers::TextHelper

  belongs_to :mission
  belongs_to :skill

  validates_numericality_of :req_vols, :only_integer => true, :greater_than => 0

  after_initialize :init

	def obtain_volunteers quantity, forbidden = nil
	  volunteers_for_mission = Volunteer.
      where(organization_id: mission.organization_id).
      geo_scope(:within => mission.max_distance, :origin => mission).
      order('distance asc')

	  unless skill.nil?
	    volunteers_for_mission = volunteers_for_mission.
        joins(:skills_volunteers).
        where('skills_volunteers.skill_id = ?', self.skill_id)
	  end

    volunteers_for_mission = volunteers_for_mission.select { |v|
      v.available_at? Time.now.utc
    }

    if forbidden
      forbidden = Set.new forbidden.map(&:id)
      volunteers_for_mission = volunteers_for_mission.reject { |v|
        forbidden.include?(v.id)
      }
    end

    volunteers_for_mission[0..quantity - 1] || []
	end

  def claim_candidates candidates, quantity = nil
    quantity ||= req_vols
    if skill
      candidates = candidates.select { |c|
        c.volunteer.skills.include?(skill)
      }
    end
    candidates.take(quantity)
  end

  def check_for_volunteers?
    self.req_vols != self.req_vols_was || self.skill_id != self.skill_id_was
  end

  def title
    skill_name = skill.present? ? skill.name : 'Volunteer'
    pluralize(req_vols, skill_name)
  end

  private

  def init
    self.req_vols ||= 1
  end
end
