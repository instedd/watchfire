class CreateChannels < ActiveRecord::Migration
  def self.up
    create_table :channels do |t|
      t.references :volunteer
      t.string :type
      t.string :address

      t.timestamps
    end
  end

  def self.down
    drop_table :channels
  end
end
