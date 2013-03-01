class CreateMissionSkills < ActiveRecord::Migration
  def self.up
    create_table :mission_skills do |t|
      t.references :mission
      t.references :skill
      t.integer :priority
      t.integer :req_vols

      t.timestamps
    end
  end

  def self.down
    drop_table :mission_skills
  end
end
