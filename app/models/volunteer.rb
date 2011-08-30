class Volunteer < ActiveRecord::Base

	acts_as_mappable

  has_many :candidates, :dependent => :destroy
  has_many :missions, :through => :candidates
	has_and_belongs_to_many :skills

  validates_presence_of :name, :lat, :lng
  
  validates_numericality_of :lat, :less_than_or_equal_to => 90, :greater_than_or_equal_to => -90
  validates_numericality_of :lng, :less_than_or_equal_to => 180, :greater_than_or_equal_to => -180
  
  validate :has_phone_or_sms

	def skill_names=(names)
		self.skills = names.split(',').map{|n| Skill.find_or_create_by_name(n)}
	end

  private

  def has_phone_or_sms
    if voice_number.blank? && sms_number.blank?
      errors[:base] << 'A volunteer has to have a voice number or an sms number'
    end
  end

end
