class CreateManyToManySkillsVolunteer < ActiveRecord::Migration
  def self.up
		create_table :skills_volunteers, :id => false do |t|
			t.integer :skill_id
			t.integer :volunteer_id
		end
  end

  def self.down
		drop_table :skills_volunteers
  end
end
