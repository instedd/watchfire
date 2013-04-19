class AddColumnsToCandidates < ActiveRecord::Migration
  def change
    add_column :candidates, :allocated_skill_id, :integer
    rename_column :candidates, :voice_status, :last_call_status
    add_column :candidates, :last_call_sid, :string

    add_index :candidates, :allocated_skill_id
    add_index :candidates, :last_call_sid
  end
end
