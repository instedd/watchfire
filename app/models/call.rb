class Call < ActiveRecord::Base
  belongs_to :candidate

  validates_presence_of :candidate, :session_id
end
