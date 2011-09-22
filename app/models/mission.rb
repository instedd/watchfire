class Mission < ActiveRecord::Base

  enum_attr :status, %w(^created running paused finished)

	acts_as_mappable

  has_many :candidates, :dependent => :destroy, :include => :volunteer
  has_many :volunteers, :through => :candidates
  has_many :mission_jobs, :dependent => :destroy

	belongs_to :skill
	belongs_to :user

  validates_presence_of :req_vols, :lat, :lng

  validates_numericality_of :req_vols, :only_integer => true, :greater_than => 0
  validates_numericality_of :lat, :less_than_or_equal_to => 90, :greater_than_or_equal_to => -90
  validates_numericality_of :lng, :less_than_or_equal_to => 180, :greater_than_or_equal_to => -180

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
    self.candidates.where(:status => :pending)
  end
  
  def confirmed_candidates
    self.candidates.where(:status => :confirmed)
  end
  
  def denied_candidates
    self.candidates.where(:status => :denied)
  end
  
  def unresponsive_candidates
    self.candidates.where(:status => :unresponsive)
  end
  
  def candidates_to_call
		self.candidates.where(:status => :pending, :paused => false)
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
    self.candidates.create! :volunteer => volunteer
  end

	def check_for_volunteers?
		self.req_vols != self.req_vols_was || self.lat != self.lat_was || self.lng != self.lng_was || self.skill_id != self.skill_id_was
	end
	
	def sms_message
	  "#{base_message} #{I18n.t :sms_confirmation}"
  end
  
  def voice_message
    base_message
  end
  
  def progress
    confirmed_candidates = candidate_count(:confirmed)
    value = confirmed_candidates > 0 ? confirmed_candidates / req_vols.to_f : 0
    [value, 1].min
  end
  
  private
  
  def base_message
    reason = self.reason.present? ? self.reason : I18n.t(:an_emergency)
    location = self.address.present? ? I18n.t(:location, :location => self.address) : ""
    I18n.t :emergency_message, :reason => reason, :location => location
  end
  
  def update_status status
    self.status = status
    self.save!
  end
  
  def available_ratio
    Watchfire::Application.config.available_ratio
  end
  
  def max_distance
    Watchfire::Application.config.max_distance
  end
  
end
