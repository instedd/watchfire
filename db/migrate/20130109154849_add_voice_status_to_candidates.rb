class AddVoiceStatusToCandidates < ActiveRecord::Migration
  def self.up
    add_column :candidates, :voice_status, :string
  end

  def self.down
    remove_column :candidates, :voice_status
  end
end
