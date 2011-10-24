class AddCustomTextToMission < ActiveRecord::Migration
  def self.up
    add_column :missions, :use_custom_text, :boolean, :default => false, :null => false
    add_column :missions, :custom_text, :text
  end

  def self.down
    remove_column :missions, :custom_text
    remove_column :missions, :use_custom_text
  end
end