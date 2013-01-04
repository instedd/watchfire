class AddOrganizationIdToMissions < ActiveRecord::Migration
  def self.up
    add_column :missions, :organization_id, :integer
  end

  def self.down
    remove_column :missions, :organization_id
  end
end
