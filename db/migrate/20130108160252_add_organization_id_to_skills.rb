class AddOrganizationIdToSkills < ActiveRecord::Migration
  def self.up
    add_column :skills, :organization_id, :integer
  end

  def self.down
    remove_column :skills, :organization_id
  end
end
