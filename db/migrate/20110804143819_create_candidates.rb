class CreateCandidates < ActiveRecord::Migration
  def self.up
    create_table :candidates do |t|
      t.references :mission
      t.references :volunteer
      t.string :status
      t.integer :voice_retries
      t.integer :sms_retries
      t.datetime :last_voice_att
      t.datetime :last_sms_att

      t.timestamps
    end
  end

  def self.down
    drop_table :candidates
  end
end
