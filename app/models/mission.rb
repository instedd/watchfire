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

  validates_presence_of :organization
  validates_presence_of :user
  validates_presence_of :lat, :lng, :name

  validates :reason, :length => { :maximum => 200 }

  validates_numericality_of :lat, :less_than_or_equal_to => 90, :greater_than_or_equal_to => -90
  validates_numericality_of :lng, :less_than_or_equal_to => 180, :greater_than_or_equal_to => -180

  after_initialize :init

	def candidate_count(st)
		return self.candidates.where('status = ?', st).count
	end

  def obtain_volunteers
    vols = []
    mission_skills.each do |mission_skill|
      num_vols = (mission_skill.req_vols / available_ratio).to_i
      vols = mission_skill.obtain_volunteers num_vols, vols
    end
    vols
  end

	def check_and_save
		if self.valid?
			if self.status_created?
				vols = self.obtain_volunteers
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
    # fetch pending and confirmed candidates ordered by the number of 
    # skills the volunteer posses, so less specialized volunteers are
    # picked first
    pending = pending_candidates.sort { |c1, c2| 
      c1.volunteer.skills.size <=> c2.volunteer.skills.size
    }
    confirmed = confirmed_candidates.sort { |c1, c2| 
      c1.volunteer.skills.size <=> c2.volunteer.skills.size
    }

    # go through each mission skill by priority and check if we got the
    # desired number of volunteers for each, creating new candidates for
    # those skills with insufficient candidates pending response
    finished = true
    mission_skills.each do |mission_skill|
      req_vols = mission_skill.req_vols

      # claim some volunteers for the skill requirement
      skill_confirmed = mission_skill.claim_candidates confirmed
      confirmed = confirmed - skill_confirmed

      if skill_confirmed.size < req_vols
        # still volunteers required for this skill
        needed = ((req_vols - skill_confirmed.size) / available_ratio).to_i
        # claim volunteers from the pending candidates pool
        skill_pending = mission_skill.claim_candidates pending, needed
        pending = pending - skill_pending

        if skill_pending.size < needed
          # not enough number of volunteers in the pending pool that can
          # fulfill this skill requirement
          recruit = needed - skill_pending.size
          # find new volunteers for this skill
          new_volunteers = mission_skill.obtain_volunteers recruit, self.volunteers
          Mission.transaction do
            new_volunteers.each {|v| add_volunteer v}
          end
          self.candidates.reload
        end
        # we're not done yet
        finished = false
      end
    end

		update_status :finished if finished
		self.save! if self.changed?
  end

  def add_volunteer volunteer
		candidate = self.candidates.create! :volunteer => volunteer
		candidate.call
  end

	def check_for_volunteers?
		mission_skills.any? { |ms| 
      ms.marked_for_destruction? || ms.new_record? ||
        ms.req_vols != ms.req_vols_was || 
        ms.skill_id != ms.skill_id_was
    } || self.lat != self.lat_was || self.lng != self.lng_was
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

  def total_req_vols
    mission_skills.map(&:req_vols).reduce(&:+)
  end

  def progress
    confirmed_candidates = candidate_count(:confirmed)
    value = confirmed_candidates > 0 ? confirmed_candidates / total_req_vols.to_f : 0
    [value, 1].min
  end

  def title
    skill_name = skill.present? ? skill.name : 'Volunteer'
    message = reason.present? ? " (#{truncate(reason, :length => 200)})" : ""
    "#{name}: #{pluralize(req_vols, skill_name)}#{message}"
  end

  def new_duplicate
    new_mission = self.clone
    new_mission.status = :created
    new_mission.save!
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

  def max_distance
    Watchfire::Application.config.max_distance
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
    mission_skills << mission_skills.new if mission_skills.empty?
  end

  def available_ratio
    Watchfire::Application.config.available_ratio
  end

end
