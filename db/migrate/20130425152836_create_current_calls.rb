class CreateCurrentCalls < ActiveRecord::Migration
  def change
    create_table :current_calls do |t|
      t.references :pigeon_channel
      t.references :candidate
      t.string :session_id
      t.string :call_status
      t.string :voice_number

      t.timestamps
    end
    add_index :current_calls, :pigeon_channel_id
    add_index :current_calls, :candidate_id
    add_index :current_calls, :session_id
    add_index :current_calls, :voice_number
  end
end
