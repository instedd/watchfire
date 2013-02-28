class Channel < ActiveRecord::Base
  validates_presence_of :address, :volunteer
end
