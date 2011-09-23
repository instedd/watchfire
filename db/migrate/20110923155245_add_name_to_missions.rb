class AddNameToMissions < ActiveRecord::Migration
  def self.up
    add_column :missions, :name, :string
  end

  def self.down
    remove_column :missions, :name
  end
end
