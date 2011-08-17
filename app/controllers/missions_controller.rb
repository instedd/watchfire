class MissionsController < ApplicationController
  def index
    @mission = Mission.first || Mission.new
		@distance = @mission.obtain_farthest
  end

	def create
		@mission = Mission.new(params[:mission])
		@distance = @mission.check_and_save
		render 'update.js'
	end

	def update
		@mission = Mission.find(params[:id])
		@mission.attributes = params[:mission]
		@distance = @mission.check_and_save
	end
	
	def start
	  @mission = Mission.find(params[:id])
	  @mission.call_volunteers
	end
	
	def stop
	  @mission = Mission.find(params[:id])
	  @mission.stop_calling_volunteers
  end
  
  def refresh
    @mission = Mission.find(params[:id])
		@distance = @mission.obtain_farthest
    respond_to do |format|
      format.html { render 'index' }
      format.js
    end
  end

end
