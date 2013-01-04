class Mission < ActiveRecord::Base
  include ActionView::Helpers::TextHelper

  enum_attr :status, %w(^created running paused finished)

	acts_as_mappable

  belongs_to :organization

  has_many :candidates, :dependent => :destroy, :include => :volunteer
  has_many :volunteers, :through => :candidates
  has_many :mission_jobs, :dependent => :destroy

	belongs_to :skill
	belongs_to :user

  validates_presence_of :organization
  validates_presence_of :req_vols, :lat, :lng, :name

  validates_numericality_of :req_vols, :only_integer => true, :greater_than => 0
  validates_numericality_of :lat, :less_than_or_equal_to => 90, :greater_than_or_equal_to => -90
  validates_numericality_of :lng, :less_than_or_equal_to => 180, :greater_than_or_equal_to => -180

  after_initialize :init

	def candidate_count(st)
		return self.candidates.where('status = ?', st).count
	end

	def obtain_volunteers quantity, offset = 0
	  volunteers_for_mission = Volunteer.geo_scope(:within => max_distance, :origin => self).order('distance asc')

	  unless skill.nil?
	    volunteers_for_mission = volunteers_for_mission.joins('INNER JOIN skills_volunteers sv ON sv.volunteer_id = volunteers.id').where('sv.skill_id' => self.skill_id)
	  end

    volunteers_for_mission.select{|v| v.available_at? Time.now.utc}[offset..offset+quantity-1] || []
	end

	def check_and_save
		if self.valid?
			if self.status_created?
				vols = self.obtain_volunteers (self.req_vols / available_ratio).to_i
				Mission.transaction do
					self.save!
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
		self.candidates.destroy_all
		vols.each do |v|
			self.candidates.create!(:volunteer_id => v.id)
		end
	end

	def farthest
		@farthest = @farthest || (self.candidates.last.volunteer.distance_from(self).round(2) rescue nil)
	end

	def call_volunteers
	  update_status :running
	  candidates_to_call.each{|c| c.call}
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

  def pending_candidates
    self.candidates.where(:status => :pending).sort
  end

  def confirmed_candidates
    self.candidates.where(:status => :confirmed).sort
  end

  def denied_candidates
    self.candidates.where(:status => :denied).sort
  end

  def unresponsive_candidates
    self.candidates.where(:status => :unresponsive).sort
  end

  def candidates_to_call
		self.candidates.where(:status => :pending, :active => true)
	end

  def check_for_more_volunteers
    pending = pending_candidates.count
    confirmed = confirmed_candidates.count
    needed = ((req_vols - confirmed) / available_ratio).to_i

    if pending < needed
      recruit = needed - pending
      volunteers = obtain_volunteers recruit, candidates.count
      Mission.transaction do
        volunteers.each{|v| add_volunteer v}
      end
			self.candidates.reload
    end
		update_status :finished if needed <= 0
		self.save! if self.changed?
  end

  def add_volunteer volunteer
		candidate = self.candidates.create! :volunteer => volunteer
		candidate.call
  end

	def check_for_volunteers?
		self.req_vols != self.req_vols_was || self.lat != self.lat_was || self.lng != self.lng_was || self.skill_id != self.skill_id_was
	end

	def sms_message
		template_or_custom_text + I18n.t(:sms_message_options)
  end

  def voice_message
		template_or_custom_text + I18n.t(:voice_message_options)
  end

	def voice_message_sentences
		voice_message.split('.').map(&:strip).reject{|s| s.blank?}
	end

  def progress
    confirmed_candidates = candidate_count(:confirmed)
    value = confirmed_candidates > 0 ? confirmed_candidates / req_vols.to_f : 0
    [value, 1].min
  end

  def title
    skill_name = skill.present? ? skill.name : 'Volunteer'
    message = reason.present? ? " (#{reason})" : ""
    "#{name}: #{pluralize(req_vols, skill_name)}#{message}"
  end

  def new_duplicate
    new_mission = self.clone
    new_mission.status = :created
    new_mission
  end

  def custom_text_changed?
    self.previous_changes.keys.include? :custom_text.to_s
  end

  def template_text
    I18n.t :template_message, :reason => reason_for_message, :location => address
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

  private

	def reason_for_message
		self.reason.present? ? self.reason : I18n.t(:an_emergency)
	end

	def template_or_custom_text
	  if use_custom_text
	    custom_text[-1] == "." ? custom_text : "#{custom_text}."
    else
      template_text
    end
	end

  def update_status status
    self.status = status
    self.save!
  end

  def init
    self.req_vols ||= 1
  end

  def available_ratio
    Watchfire::Application.config.available_ratio
  end

  def max_distance
    Watchfire::Application.config.max_distance
  end

end
