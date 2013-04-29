class DropCalls < ActiveRecord::Migration
  def up
    drop_table :calls
  end
end
