class CreateMissions < ActiveRecord::Migration
  def self.up
    create_table :missions do |t|
      t.integer :req_vols
      t.float :lat
      t.float :lng
      t.string :reason
      t.string :status
      t.string :address

      t.timestamps
    end
  end

  def self.down
    drop_table :missions
  end
end
