class MissionJob < ActiveRecord::Base
  belongs_to :mission
  belongs_to :job, :class_name => "::Delayed::Job", :dependent => :destroy
  
  validates_presence_of :mission, :job
  validates_uniqueness_of :mission_id, :scope => :job_id
end