class AddPausedToCandidates < ActiveRecord::Migration
  def self.up
    add_column :candidates, :paused, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :candidates, :paused
  end
end
