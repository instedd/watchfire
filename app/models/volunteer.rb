class Volunteer < ActiveRecord::Base

  acts_as_mappable

  belongs_to :organization

  has_many :candidates, :dependent => :destroy
  has_many :missions, :through => :candidates
  has_many :skills_volunteers, :dependent => :delete_all
  has_many :skills, :through => :skills_volunteers

  has_many :channels
  has_many :sms_channels, :dependent => :destroy, :inverse_of => :volunteer, :autosave => true
  has_many :voice_channels, :dependent => :destroy, :inverse_of => :volunteer, :autosave => true

  serialize :shifts

  validates_presence_of :organization
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :organization_id
  validates_length_of :name, :maximum => 100

  validates_numericality_of :lat, :less_than_or_equal_to => 90, :greater_than_or_equal_to => -90, :if => Proc.new{|x| x.lat.present?}
  validates_numericality_of :lng, :less_than_or_equal_to => 180, :greater_than_or_equal_to => -180, :if => Proc.new{|x| x.lng.present?}

  validate :has_channel
  validate :has_location

  default_scope includes(:voice_channels, :sms_channels)

  def skill_names=(names)
    self.skills = names.split(',').map{|n| Skill.find_or_create_by_organization_id_and_name(organization_id, n.strip)}.select(&:valid?)
  end

  def skill_names
    self.skills.map(&:name).join(', ')
  end

  def shifts_json=(shifts)
    self.shifts = JSON.parse(shifts) rescue nil
  end

  def shifts_json
    shifts.to_json
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

  def voice_numbers
    self.voice_channels.reject{|c|c.marked_for_destruction?}.map(&:address).join(', ')
  end

  def voice_numbers=(numbers)
    if numbers.is_a? String
      numbers = numbers.split(',')
    end
    self.voice_channels.each do |vc|
      vc.mark_for_destruction
    end
    numbers.each do |number|
      self.voice_channels.build(:address => number.strip)
    end
  end

  def has_voice_number?(number)
    voice_channels.reject { |c| c.marked_for_destruction? }.map(&:address).include?(number)
  end

  def has_voice?
    voice_channels.any?
  end

  def ordered_voice_numbers
    voice_channels.sort_by(&:id).map(&:address)
  end

  def is_last_voice_number?(number)
    ordered_voice_numbers.last == number
  end

  def sms_numbers
    self.sms_channels.reject{|c|c.marked_for_destruction?}.map(&:address).join(', ')
  end

  def sms_numbers=(numbers)
    if numbers.is_a? String
      numbers = numbers.split(',')
    end
    self.sms_channels.each do |sc|
      sc.mark_for_destruction
    end
    numbers.each do |number|
      self.sms_channels.build(:address => number.strip)
    end
  end

  def has_sms_number?(number)
    sms_channels.reject { |c| c.marked_for_destruction? }.map(&:address).include?(number)
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
      errors[:address] << (address.blank? ? "can't be blank" : "is invalid")
    end
  end

end
