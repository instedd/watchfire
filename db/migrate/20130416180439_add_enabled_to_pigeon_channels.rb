class AddEnabledToPigeonChannels < ActiveRecord::Migration
  def change
    add_column :pigeon_channels, :enabled, :boolean, :default => true
  end
end
