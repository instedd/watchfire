class Candidate < ActiveRecord::Base
  
  enum_attr :status, %w(confirmed ^pending denied unresponsive)

  belongs_to :mission
  belongs_to :volunteer
	
  has_many :calls, :dependent => :destroy

  validates_presence_of :mission_id, :volunteer_id, :voice_retries, :sms_retries

  validates_numericality_of :voice_retries, :only_integer => true, :greater_than_or_equal_to => 0
  validates_numericality_of :sms_retries, :only_integer => true, :greater_than_or_equal_to => 0
  
  validates_uniqueness_of :volunteer_id, :scope => :mission_id, :on => :create

	after_initialize :init
	
	def self.find_last_for_sms_number number
    Candidate.joins(:volunteer).where(:volunteers => {:sms_number => number}).order('last_sms_att DESC').readonly(false).first
  end
  
  def self.find_by_call_session_id id
    Call.find_by_session_id(id).candidate rescue nil
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
    has_sms_retries? || has_voice_retries?
  end
  
  def has_sms_retries?
    has_sms? && self.sms_retries < config.max_sms_retries
  end
  
  def has_voice_retries?
    has_voice? && self.voice_retries < config.max_voice_retries
  end
  
  def update_status status
    self.status = status
    self.save!
    mission.check_for_more_volunteers
  end
  
  def response_message
    I18n.t(confirmed? ? :response_confirmed : :response_denied)
  end
  
  def last_call
    self.calls.order('created_at DESC').first
  end
  
  private

	def init
		self.voice_retries ||= 0
		self.sms_retries ||= 0
	end
	
	def config
	  Watchfire::Application.config
	end

end
