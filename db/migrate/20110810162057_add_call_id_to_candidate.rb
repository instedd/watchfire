class AddCallIdToCandidate < ActiveRecord::Migration
  def self.up
    add_column :candidates, :call_id, :string
  end

  def self.down
    remove_column :candidates, :call_id
  end
end