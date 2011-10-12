class RemoveCallIdFromCandidate < ActiveRecord::Migration
  def self.up
		remove_column :candidates, :call_id
  end

  def self.down
    add_column :candidates, :call_id, :string
  end
end
