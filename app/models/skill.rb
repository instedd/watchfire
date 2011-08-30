class Skill < ActiveRecord::Base

	scope :actives, where('id IN (SELECT skill_id from skills_volunteers) OR id IN (SELECT skill_id from missions)')

	validates_presence_of :name

	has_and_belongs_to_many :volunteers

	has_many :missions

end
