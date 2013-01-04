class AddOrganizationIdToVolunteers < ActiveRecord::Migration
  def self.up
    add_column :volunteers, :organization_id, :integer
  end

  def self.down
    remove_column :volunteers, :organization_id
  end
end
