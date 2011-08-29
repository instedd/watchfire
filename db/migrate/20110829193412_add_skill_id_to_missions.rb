class AddSkillIdToMissions < ActiveRecord::Migration
  def self.up
    add_column :missions, :skill_id, :integer, :default => nil
  end

  def self.down
    remove_column :missions, :skill_id
  end
end
