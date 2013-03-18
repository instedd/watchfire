class AddLastVoiceNumberToCandidate < ActiveRecord::Migration
  def change
    add_column :candidates, :last_voice_number, :string
  end
end
