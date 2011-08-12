class Mission < ActiveRecord::Base

  enum_attr :status, %w(^created running paused finished)

	acts_as_mappable

  has_many :candidates, :dependent => :destroy, :include => :volunteer
  has_many :volunteers, :through => :candidates

  validates_presence_of :req_vols, :lat, :lng

  validates_numericality_of :req_vols, :only_integer => true, :greater_than => 0
  validates_numericality_of :lat, :less_than_or_equal_to => 90, :greater_than_or_equal_to => -90
  validates_numericality_of :lng, :less_than_or_equal_to => 180, :greater_than_or_equal_to => -180

	def candidate_count(st)
		return self.candidates.where('status = ?', st).count
	end

	def obtain_volunteers
		Volunteer.geo_scope(:origin => self).order('distance asc').limit((self.req_vols / Watchfire::Application.config.available_ratio).to_i)
	end

	def check_and_save
		if self.valid?
			vols = self.obtain_volunteers
			Mission.transaction do
				self.save!
				set_candidates vols
			end
			return vols.last.distance_from(self) rescue nil
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
		self.candidates.last.volunteer.distance_from(self) rescue nil
	end
	
	def call_volunteers
	  update_status :running
	  pending_candidates.each{|c| c.call}
  end
  
  def stop_calling_volunteers
    update_status :paused
  end
  
  def pending_candidates
    self.candidates.where(:status => :pending)
  end
  
  private
  
  def update_status status
    self.status = status
    self.save!
  end

end
