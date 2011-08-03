class Volunteer < ActiveRecord::Base

  validates_presence_of :name, :lat, :lng
  
  validates_numericality_of :lat, :less_than_or_equal_to => 90, :greater_than_or_equal_to => -90
  validates_numericality_of :lng, :less_than_or_equal_to => 180, :greater_than_or_equal_to => -180
  
  validate :has_phone_or_sms

  private

  def has_phone_or_sms
    if voice_number.blank? && sms_number.blank?
      errors[:base] << 'A volunteer has to have a voice number or an sms number'
    end
  end

end
