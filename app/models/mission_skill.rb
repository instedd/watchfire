class MissionSkill < ActiveRecord::Base
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
        joins('INNER JOIN skills_volunteers sv ON sv.volunteer_id = volunteers.id').
        where('sv.skill_id' => self.skill_id)
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

  private

  def init
    self.req_vols ||= 1
  end
end
