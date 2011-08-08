class MissionsController < ApplicationController
  def index
    @mission = Mission.first || Mission.new
  end

	def create
		@mission = Mission.new(params[:mission])
		if @mission.valid?
			set_candidates @mission.obtain_volunteers
		end
		render :action => 'index'
	end

	def update
	end

	private	

	def set_candidates(vols)
		@mission.candidates.destroy_all
		@mission.candidates = vols.map{|v| Candiate.new(:volunteer_id => v.id)}
		@mission.candidates.each do |c|
			c.save
		end
		@mission.save
		@distance = vols.last.distance_from(@mission)
	end

end
