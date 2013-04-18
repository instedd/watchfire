class AddLimitToPigeonChannels < ActiveRecord::Migration
  def change
    add_column :pigeon_channels, :limit, :integer, :default => 1
  end
end
