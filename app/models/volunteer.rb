class Volunteer < ActiveRecord::Base

	acts_as_mappable

  has_many :candidates, :dependent => :destroy
  has_many :missions, :through => :candidates
	has_and_belongs_to_many :skills
	
	serialize :shifts

  validates_presence_of :name
  validates_uniqueness_of :name
  
  validates_numericality_of :lat, :less_than_or_equal_to => 90, :greater_than_or_equal_to => -90, :if => Proc.new{|x| x.lat.present?}
  validates_numericality_of :lng, :less_than_or_equal_to => 180, :greater_than_or_equal_to => -180, :if => Proc.new{|x| x.lng.present?}
  
  validate :has_phone_or_sms
  validate :has_location

	def skill_names=(names)
		self.skills = names.split(',').map{|n| Skill.find_or_create_by_name(n)}.select{|s| s.valid?}
	end
	
	def skill_names
	  self.skills.map(&:name).join(',')
  end
	
	def available? day, hour
	  begin
	    self.shifts[day.to_s][hour.to_s] == "1"
    rescue
      true
    end
  end
  
  def available_at? time
    day = Day.at time
    hour = time.hour
    self.available? day, hour
  end

  private

  def has_phone_or_sms
    if voice_number.blank? && sms_number.blank?
      errors[:base] << 'A volunteer has to have a voice number or an sms number'
    end
  end
  
  def has_location
    if lat.blank? || lng.blank?
      errors[:address] << "can't be blank"
    end
  end

end
