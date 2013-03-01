class MigrateMissionSkills < ActiveRecord::Migration
  class Mission < ActiveRecord::Base
  end
  class MissionSkill < ActiveRecord::Base
    belongs_to :mission
  end

  def self.up
    Mission.all.each do |mission|
      MissionSkill.create! :mission => mission, :priority => 1, :req_vols => mission.req_vols, :skill_id => mission.skill_id
    end

    remove_column :missions, :req_vols
    remove_column :missions, :skill_id
  end

  def self.down
    add_column :missions, :req_vols, :integer
    add_column :missions, :skill_id, :integer

    Mission.all.each do |mission|
      mission_skill = MissionSkill.where(:mission_id => mission.id).order(:priority).first
      if mission_skill
        mission.req_vols = mission_skill.req_vols
        mission.skill_id = mission_skill.skill_id
      else
        mission.req_vols = 1
      end
      mission.save!
    end
  end
end
