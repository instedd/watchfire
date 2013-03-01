class AddVoiceNumberToCalls < ActiveRecord::Migration
  def self.up
    add_column :calls, :voice_number, :string
  end

  def self.down
    remove_column :calls, :voice_number
  end
end
