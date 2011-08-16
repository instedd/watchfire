class CreateMissionJobs < ActiveRecord::Migration
  def self.up
    create_table :mission_jobs do |t|
      t.references :mission, :null => false
      t.references :job, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :mission_jobs
  end
end
