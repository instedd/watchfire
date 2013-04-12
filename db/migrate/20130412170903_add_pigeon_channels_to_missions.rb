class AddPigeonChannelsToMissions < ActiveRecord::Migration
  def change
    add_column :missions, :verboice_channel_id, :integer
    add_column :missions, :nuntium_channel_id, :integer

    add_index :missions, :verboice_channel_id
    add_index :missions, :nuntium_channel_id
  end
end
