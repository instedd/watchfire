class Skill < ActiveRecord::Base

	scope :actives, where('id IN (SELECT skill_id from skills_volunteers) OR id IN (SELECT skill_id from mission_skills)')

	belongs_to :organization
	has_and_belongs_to_many :volunteers

	has_many :missions, :dependent => :nullify

	validates_presence_of :organization
	validates_presence_of :name
	validate :name_not_volunteer

	def pluralized
		self.name.pluralize
	end

	private

	def name_not_volunteer
		name_downcase = name.try(:downcase)
		if name_downcase == "volunteer" || name_downcase == "volunteers"
			errors[:name] << "can't be used"
		end
	end

end
