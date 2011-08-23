class Mission < ActiveRecord::Base

  enum_attr :status, %w(^created running paused finished)

	acts_as_mappable

  has_many :candidates, :dependent => :destroy, :include => :volunteer
  has_many :volunteers, :through => :candidates
  has_many :mission_jobs, :dependent => :destroy

  validates_presence_of :req_vols, :lat, :lng

  validates_numericality_of :req_vols, :only_integer => true, :greater_than => 0
  validates_numericality_of :lat, :less_than_or_equal_to => 90, :greater_than_or_equal_to => -90
  validates_numericality_of :lng, :less_than_or_equal_to => 180, :greater_than_or_equal_to => -180

	def candidate_count(st)
		return self.candidates.where('status = ?', st).count
	end

	def obtain_volunteers quantity, offset = 0
		Volunteer.geo_scope(:origin => self).order('distance asc').limit(quantity).offset(offset)
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

	def obtain_farthest
		self.candidates.last.volunteer.distance_from(self).round(2) rescue nil
	end
	
	def call_volunteers
	  update_status :running
	  pending_candidates.each{|c| c.call}
  end
  
  def stop_calling_volunteers
    update_status :paused
    self.mission_jobs.destroy_all
  end
  
  def pending_candidates
    self.candidates.where(:status => :pending)
  end
  
  def confirmed_candidates
    self.candidates.where(:status => :confirmed)
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

	def need_check_candidates
		self.req_vols != self.req_vols_was || self.lat != self.lat_was || self.lng != self.lng_was
	end
  
  private
  
  def update_status status
    self.status = status
    self.save!
  end
  
  def available_ratio
    Watchfire::Application.config.available_ratio
  end
  
end
