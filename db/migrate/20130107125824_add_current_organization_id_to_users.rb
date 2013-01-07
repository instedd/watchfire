class AddCurrentOrganizationIdToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :current_organization_id, :integer
  end

  def self.down
    remove_column :users, :current_organization_id
  end
end
