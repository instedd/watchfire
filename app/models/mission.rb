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
		self.candidates = vols.map{|v| Candidate.new(:volunteer_id => v.id, :mission_id => self.id)}
		self.candidates.each do |c|
			c.save!
		end
	end

	def obtain_farthest
		self.candidates.last.volunteer.distance_from(self) rescue nil
	end

end
