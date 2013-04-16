class RemoveCustomTextFromMission < ActiveRecord::Migration
  def change
    remove_column :missions, :use_custom_text
    remove_column :missions, :custom_text
  end
end
