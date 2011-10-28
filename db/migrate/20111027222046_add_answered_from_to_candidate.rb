class AddAnsweredFromToCandidate < ActiveRecord::Migration
  def self.up
    add_column :candidates, :answered_from, :string
    add_column :candidates, :answered_at, :datetime
  end

  def self.down
    remove_column :candidates, :answered_at
    remove_column :candidates, :answered_from
  end
end