class Candidate < ActiveRecord::Base

  enum_attr :status, %w(confirmed ^pending denied unresponsive)

  belongs_to :mission
  belongs_to :volunteer
  belongs_to :allocated_skill, :class_name => "Skill"

  has_many :calls, :dependent => :destroy
  has_many :current_calls, :dependent => :destroy

  validates_presence_of :mission_id, :volunteer_id, :voice_retries, :sms_retries

  validates_numericality_of :voice_retries, :only_integer => true, :greater_than_or_equal_to => 0
  validates_numericality_of :sms_retries, :only_integer => true, :greater_than_or_equal_to => 0

  validates_uniqueness_of :volunteer_id, :scope => :mission_id, :on => :create

  after_initialize :init

  def self.find_last_for_sms_number number
    Candidate.joins(:volunteer => [:sms_channels]).where(:channels =>{:address => number}).order('last_sms_att DESC').readonly(false).first
  end

  def self.find_last_for_voice_number number
    Candidate.joins(:volunteer => [:voice_channels]).where(:channels =>{:address => number}).order('last_voice_att DESC').readonly(false).first
  end

  def self.find_by_call_session_id id
    CurrentCall.find_by_session_id(id).candidate rescue nil
  end

  def has_sms?
    volunteer.sms_channels.size > 0
  end

  def has_voice?
    volunteer.voice_channels.size > 0
  end

  def organization
    volunteer.organization
  end

  def max_sms_retries
    organization.max_sms_retries
  end

  def max_voice_retries
    organization.max_voice_retries
  end

  def sms_timeout
    organization.sms_timeout
  end

  def voice_timeout
    organization.voice_timeout
  end

  def has_retries?
    has_sms_retries? || has_voice_retries?
  end

  def has_sms_retries?
    has_sms? && self.sms_retries < max_sms_retries
  end

  def has_voice_retries?
    has_voice? && self.voice_retries < max_voice_retries
  end

  def response_message
    confirmed? ? mission.confirm_message : mission.deny_message
  end

  def last_call
    self.calls.order('created_at DESC').first
  end

  def enable!
    self.active = true
    self.save!
  end

  def disable!
    self.active = false
    self.save!
  end

  def <=>(other)
    self.volunteer.name <=> other.volunteer.name
  end

  def answered_from_sms!(response, number)
    new_status = response == "yes" ? :confirmed : :denied
    update_status new_status, number
  end

  def answered_from_voice!(response, number)
    new_status = response == "1" ? :confirmed : :denied
    update_status new_status, number
  end

  def no_answer!
    self.status = :unresponsive
    save_and_check!
  end

  private

  def update_status(new_status, from)
    self.status = new_status
    self.answered_from = from
    self.answered_at = Time.now.utc
    if new_status == :confirmed
      self.allocated_skill = mission.preferred_skill_for_candidate(self)
    end
    save_and_check!
  end

  def save_and_check!
    self.save!
    SchedulerAdvisor.candidate_status_updated self
  end

  def init
    self.voice_retries ||= 0
    self.sms_retries ||= 0
  end

  def config
    Watchfire::Application.config
  end

end
