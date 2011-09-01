class AddShiftsToVolunteers < ActiveRecord::Migration
  def self.up
    add_column :volunteers, :shifts, :text
  end

  def self.down
    remove_column :volunteers, :shifts
  end
end
