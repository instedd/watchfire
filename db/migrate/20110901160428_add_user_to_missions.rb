class AddUserToMissions < ActiveRecord::Migration
  def self.up
    add_column :missions, :user_id, :integer
  end

  def self.down
    remove_column :missions, :user_id
  end
end
