class Candidate < ActiveRecord::Base
  
  enum_attr :status, %w(confirmed ^pending denied unresponsive)

  belongs_to :mission
  belongs_to :volunteer

  validates_presence_of :mission_id, :volunteer_id, :voice_retries, :sms_retries

  validates_numericality_of :voice_retries, :only_integer => true, :greater_than_or_equal_to => 0
  validates_numericality_of :sms_retries, :only_integer => true, :greater_than_or_equal_to => 0
  
  validates_uniqueness_of :volunteer_id, :scope => :mission_id, :on => :create

	after_initialize :init
	
	def self.find_last_for_sms_number number
    Candidate.joins(:volunteer).where(:volunteers => {:sms_number => number}).order('last_sms_att DESC').readonly(false).first
  end
  
  def has_sms?
    !self.volunteer.sms_number.nil? && !self.volunteer.sms_number.blank?
  end
  
  def has_voice?
    !self.volunteer.voice_number.nil? && !self.volunteer.voice_number.blank?
  end
  
  def call
    Delayed::Job.enqueue(SmsJob.new(self.id)) if self.has_sms?
    Delayed::Job.enqueue(VoiceJob.new(self.id)) if self.has_voice?
  end
  
  def has_retries?
    config = Watchfire::Application.config
    self.sms_retries < config.max_sms_retries || self.voice_retries < config.max_voice_retries
  end
  
  private

  def not_same_volunteer_same_mission
    if Candidate.where("mission_id = ? AND volunteer_id = ?", self.mission_id, self.volunteer_id).count > 0
      errors[:base] << 'The volunteer is already in the candidate list for the mission'
    end
  end

	def init
		self.voice_retries ||= 0
		self.sms_retries ||= 0
	end

end
