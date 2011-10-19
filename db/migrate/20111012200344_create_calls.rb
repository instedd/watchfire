class CreateCalls < ActiveRecord::Migration
  def self.up
    create_table :calls do |t|
      t.string :session_id
      t.references :candidate

      t.timestamps
    end
  end

  def self.down
    drop_table :calls
  end
end
