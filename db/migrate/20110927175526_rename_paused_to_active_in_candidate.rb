class RenamePausedToActiveInCandidate < ActiveRecord::Migration
  def self.up
    rename_column :candidates, :paused, :active
  end

  def self.down
    rename_column :candidates, :active, :paused
  end
end