class Volunteer < ActiveRecord::Base

	acts_as_mappable

  has_many :candidates, :dependent => :destroy
  has_many :missions, :through => :candidates
	has_and_belongs_to_many :skills
	
	has_many :sms_channels, :dependent => :destroy, :inverse_of => :volunteer
	has_many :voice_channels, :dependent => :destroy, :inverse_of => :volunteer
	
	serialize :shifts

  validates_presence_of :name
  validates_uniqueness_of :name
  
  validates_numericality_of :lat, :less_than_or_equal_to => 90, :greater_than_or_equal_to => -90, :if => Proc.new{|x| x.lat.present?}
  validates_numericality_of :lng, :less_than_or_equal_to => 180, :greater_than_or_equal_to => -180, :if => Proc.new{|x| x.lng.present?}
  
  validate :has_channel
  validate :has_location
	
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

	# View Helpers
	def skill_names=(names)
		self.skills = names.split(',').map{|n| Skill.find_or_create_by_name(n)}.select{|s| s.valid?}
	end
	
	def skill_names
	  self.skills.map(&:name).join(',')
  end
	
	def voice_numbers
		self.voice_channels.reject{|c|c.marked_for_destruction?}.map(&:address).join(', ')
	end
	
	def voice_numbers=(numbers)
		self.voice_channels = numbers.split(',').map{|number| VoiceChannel.new(:address => number.strip)}
	end
	
	def sms_numbers
		self.sms_channels.reject{|c|c.marked_for_destruction?}.map(&:address).join(', ')
	end
	
	def sms_numbers=(numbers)
		self.sms_channels = numbers.split(',').map{|number| SmsChannel.new(:address => number.strip)}
	end

  private

  def has_channel
		sms_channels_count = sms_channels.reject{|c| c.marked_for_destruction?}.size
		voice_channels_count = voice_channels.reject{|c| c.marked_for_destruction?}.size
    if sms_channels_count == 0 && voice_channels_count == 0
      errors[:base] << 'A volunteer has to have a voice number or an sms number'
    end
  end
  
  def has_location
    if lat.blank? || lng.blank?
      errors[:address] << "can't be blank"
    end
  end

end
