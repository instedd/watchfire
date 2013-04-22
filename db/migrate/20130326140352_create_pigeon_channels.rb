class CreatePigeonChannels < ActiveRecord::Migration
  def change
    create_table :pigeon_channels do |t|
      t.references :organization
      t.string :name
      t.string :description
      t.string :channel_type
      t.string :pigeon_name

      t.timestamps
    end
    add_index :pigeon_channels, :organization_id
  end
end
