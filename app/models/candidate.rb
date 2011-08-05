class Candidate < ActiveRecord::Base
  
  enum_attr :status, %w(^pending confirmed denied unresponsive)

  belongs_to :mission
  belongs_to :volunteer

  validates_presence_of :mission_id, :volunteer_id, :voice_retries, :sms_retries

  validates_numericality_of :voice_retries, :only_integer => true, :greater_than_or_equal_to => 0
  validates_numericality_of :sms_retries, :only_integer => true, :greater_than_or_equal_to => 0

  validate :not_same_volunteer_same_mission

	after_initialize :init

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
