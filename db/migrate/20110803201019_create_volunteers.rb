class CreateVolunteers < ActiveRecord::Migration
  def self.up
    create_table :volunteers do |t|
      t.string :name
      t.float :lat
      t.float :lng
      t.string :address
      t.string :voice_number
      t.string :sms_number

      t.timestamps
    end
  end

  def self.down
    drop_table :volunteers
  end
end
