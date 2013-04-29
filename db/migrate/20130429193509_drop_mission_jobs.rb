class DropMissionJobs < ActiveRecord::Migration
  def up
    drop_table :mission_jobs
  end
end
