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

  accepts_nested_attributes_for :mission_skills, :allow_destroy => true

  belongs_to :verboice_channel, :class_name => 'PigeonChannel'
  belongs_to :nuntium_channel, :class_name => 'PigeonChannel'

  validate :channels_are_valid
  validate :has_channels_when_running

	def candidate_count(st)
		return self.candidates.where('status = ?', st).count
	end

  def add_mission_skill params = {}
    new_priority = (mission_skills.maximum('priority') || 0) + 1
    mission_skills.build({ :priority => new_priority }.merge(params))
  end

  def obtain_volunteers
    vols = []
    mission_skills.each do |mission_skill|
      mission_skill.mission = self  # needed to successfully call obtain_volunteers
      num_vols = (mission_skill.req_vols / available_ratio).to_i
      vols = vols + mission_skill.obtain_volunteers(num_vols, vols)
    end
    vols
  end

	def check_and_save
		if self.valid?
			if self.status_created?
				Mission.transaction do
					self.save!
          mission_skills.reload
          vols = self.obtain_volunteers
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
    begin
      update_status :running
      candidates_to_call.each{|c| c.call}
    rescue ActiveRecord::RecordInvalid
      self.status = self.status_was
    end
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

  def allocate_candidates confirmed, pending
    # go through each mission skill by priority and check if we got the desired
    # number of volunteers for each by allocating confirmed and pending
    # candidates
    mission_skills.map do |mission_skill|
      data = { :mission_skill => mission_skill }

      data[:confirmed] = mission_skill.claim_candidates confirmed
      confirmed = confirmed - data[:confirmed]

      if data[:confirmed].size < mission_skill.req_vols
        data[:needed] = ((mission_skill.req_vols - data[:confirmed].size) / available_ratio).to_i
        data[:pending] = mission_skill.claim_candidates pending, data[:needed]
        pending = pending - data[:pending]
      else
        data[:pending] = []
        data[:needed] = 0
      end

      data
    end
  end

  def candidate_allocation_order
    # by default, candidates are ordered by the number of skills the volunteer
    # posses, so less specialized volunteers are allocated first
    Proc.new do |c1, c2| 
      c1.volunteer.skills.size <=> c2.volunteer.skills.size
    end
  end

  def check_for_more_volunteers
    # allocate the confirmed and pending candidates to the required skills for
    # the mission
    pending = pending_candidates.sort(&candidate_allocation_order)
    confirmed = confirmed_candidates.sort(&candidate_allocation_order)
    allocation = allocate_candidates(confirmed, pending)

    # for each mission skill with allocated candidates, check if we need to add
    # new volunteers to fulfill the required number
    finished = true
    allocation.each do |data|
      if data[:needed] > 0
        if data[:pending].size < data[:needed]
          # not enough number of volunteers in the pending pool that can
          # fulfill this skill requirement
          recruit = data[:needed] - data[:pending].size
          # find new volunteers for this skill
          new_volunteers = data[:mission_skill].obtain_volunteers recruit, self.volunteers
          Mission.transaction do
            new_volunteers.each {|v| add_volunteer v}
          end
          self.candidates.reload
        end
        # we're not done yet
        finished = false
      end
    end

		finish if finished
		self.save! if self.changed?
  end

  def add_volunteer volunteer
		candidate = self.candidates.create! :volunteer => volunteer
		candidate.call
  end

	def check_for_volunteers?
		mission_skills.any? { |ms| 
      ms.marked_for_destruction? || ms.new_record? || ms.check_for_volunteers?
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
    requirements = mission_skills.map(&:title).join(', ')
    message = reason.present? ? " (#{truncate(reason, :length => 200)})" : ""
    "#{name}: #{requirements}#{message}"
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

  def unlink_channel! channel
    if channel == verboice_channel
      update_attribute :verboice_channel, nil
    elsif channel == nuntium_channel
      update_attribute :nuntium_channel, nil
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

  def available_ratio
    Watchfire::Application.config.available_ratio
  end

  def channels_are_valid
    [:verboice, :nuntium].each do |type|
      attribute = "#{type}_channel".to_sym
      channel = self.send(attribute)
      if channel.present?
        if channel.organization != organization
          errors[attribute] << 'belongs to another organization'
        end
        if channel.channel_type != type
          errors[attribute] << 'has an invalid type'
        end
      end
    end
  end

  def has_channels_when_running
    if status == :running && ![verboice_channel, nuntium_channel].any?
      errors.add :verboice_channel, "Cannot start recruiting unless event has at least one channel"
      errors.add :nuntium_channel, "Cannot start recruiting unless event has at least one channel"
    end
    errors.blank?
  end

end
