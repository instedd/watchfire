class Mission < ActiveRecord::Base
  include ActionView::Helpers::TextHelper

  enum_attr :status, %w(^created running paused finished)

	acts_as_mappable

  belongs_to :organization

  has_many :candidates, :dependent => :destroy, :include => :volunteer
  has_many :volunteers, :through => :candidates
  has_many :mission_jobs, :dependent => :destroy
  has_many :mission_skills, :dependent => :destroy, :include => :skill, :order => "priority ASC"

	belongs_to :user

  store :messages, accessors: [:intro_text, :desc_text, :question_text, :yes_text, :no_text, :location_type, :confirm_human]

  validates_presence_of :organization
  validates_presence_of :user
  validates_presence_of :lat, :lng, :name

  validates :reason, :length => { :maximum => 200 }

  validates_numericality_of :lat, :less_than_or_equal_to => 90, :greater_than_or_equal_to => -90
  validates_numericality_of :lng, :less_than_or_equal_to => 180, :greater_than_or_equal_to => -180

  accepts_nested_attributes_for :mission_skills, :allow_destroy => true

  before_create :init_messages

  include Mission::AllocationConcern

	def candidate_count(st)
		return self.candidates.where('status = ?', st).count
	end

  def add_mission_skill params = {}
    new_priority = (mission_skills.maximum('priority') || 0) + 1
    mission_skills.build({ :priority => new_priority }.merge(params))
  end

	def check_and_save
		if self.valid?
			if self.status_created?
				Mission.transaction do
					self.save!
          mission_skills.reload
          vols = self.obtain_initial_volunteers
					set_candidates vols
				end
				self.candidates.reload
			else
				self.check_for_more_volunteers
			end
		end
		nil
	end

  def set_candidates(vols)
    new_volunteers = Set.new vols.map(&:id)
    self.candidates.each do |c|
      if not new_volunteers.delete?(c.volunteer_id)
        c.destroy
      end
    end
    new_volunteers.each do |vid|
      self.candidates.create!(:volunteer_id => vid)
    end
    self.candidates.reload
  end

	def farthest
		@farthest = @farthest || (self.volunteers.geo_scope(:origin => self).order("distance DESC").first.distance.round(2) rescue nil)
	end

  def call_volunteers
    update_status :running
    SchedulerAdvisor.mission_started self
    #candidates_to_call.each{|c| c.call}
  end

  def stop_calling_volunteers
    update_status :paused
    self.mission_jobs.destroy_all
  end

  def finish
    update_status :finished
    self.mission_jobs.destroy_all
  end

  def open
    update_status :paused
  end

  def candidates_with_channels
    self.candidates.includes(:volunteer => [:voice_channels, :sms_channels])
  end

  def pending_candidates
    self.candidates_with_channels.where(:status => :pending).sort
  end

  def confirmed_candidates
    self.candidates_with_channels.where(:status => :confirmed).sort
  end

  def denied_candidates
    self.candidates_with_channels.where(:status => :denied).sort
  end

  def unresponsive_candidates
    self.candidates_with_channels.where(:status => :unresponsive).sort
  end

  def candidates_to_call
    self.candidates.where(:status => :pending, :active => true)
  end

  def add_volunteer volunteer
		candidate = self.candidates.create
    candidate.volunteer = volunteer
    candidate.save!

		candidate.call
  end

	def check_for_volunteers?
		mission_skills.any? { |ms|
      ms.marked_for_destruction? || ms.new_record? || ms.check_for_volunteers?
    } || self.lat != self.lat_was || self.lng != self.lng_was
	end

  def sms_message
    full_message + I18n.t(:sms_message_options)
  end

  def voice_message
		full_message + I18n.t(:voice_message_options)
  end

  def voice_before_confirmation_message
    before_confirmation_message + I18n.t(:human_message)
  end

  def voice_after_confirmation_message
    after_confirmation_message + I18n.t(:voice_message_options)
  end

  def total_req_vols
    mission_skills.map(&:req_vols).reduce(&:+)
  end

  def progress
    confirmed_candidates = candidate_count(:confirmed)
    value = confirmed_candidates > 0 ? confirmed_candidates / total_req_vols.to_f : 0
    [value, 1].min
  end

  def title
    requirements = mission_skills.map(&:title).join(', ')
    message = reason.present? ? " (#{truncate(reason, :length => 200)})" : ""
    "#{name}: #{requirements}#{message}"
  end

  def enable_all_pending
    pending_candidates.each do |candidate|
      candidate.enable!
    end
  end

  def disable_all_pending
    pending_candidates.each do |candidate|
      candidate.disable!
    end
  end

  def confirm_message
    "#{yes_text.strip_sentence} #{address}"
  end

  def deny_message
    no_text
  end

  def confirm_human?
    self.confirm_human == '1'
  end

  private

	def reason_for_message
		self.reason.present? ? self.reason : I18n.t(:an_emergency)
	end

  def update_status status
    self.status = status
    self.save!
  end

  def init_messages
    self.intro_text = I18n.t(:intro_message, :organization => self.organization.name)
    self.desc_text = I18n.t(:desc_message, :reason => reason_for_message)
    self.question_text = I18n.t(:question_message)
    self.yes_text = I18n.t(:yes_message)
    self.no_text = I18n.t(:no_message)
    self.location_type = 'city'
    self.confirm_human = '1'
    true
  end

  def location
    location_type == 'address' ? address : city
  end

  def full_message
    # message = ''
    # message << intro_text.to_sentence
    # message << (desc_text.strip_sentence + ' ')
    # message << location.to_sentence
    # message << question_text.to_sentence
    # message
    before_confirmation_message + after_confirmation_message
  end

  def before_confirmation_message
    intro_text.to_sentence
  end

  def after_confirmation_message
    message = desc_text.strip_sentence + ' '
    message << location.to_sentence
    message << question_text.to_sentence
    message
  end

end
