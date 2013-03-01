class Channel < ActiveRecord::Base
  ADDRESS_REGEX = /\A\+?[\s\d\.\-\(\)]+\Z/

  validates_presence_of :address, :volunteer

  validates_format_of :address, :with => ADDRESS_REGEX
end
