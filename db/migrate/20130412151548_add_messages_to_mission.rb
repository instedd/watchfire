class AddMessagesToMission < ActiveRecord::Migration
  def change
    add_column :missions, :messages, :text
  end
end
