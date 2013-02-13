class RenameOrganizationUsersToMembers < ActiveRecord::Migration
  def self.up
    rename_table :organization_users, :members
  end

  def self.down
    rename_table :members, :organization_users
  end
end
