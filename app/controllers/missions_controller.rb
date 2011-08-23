class MissionsController < ApplicationController

	before_filter :authenticate_user!

  def index
    @mission = Mission.first || Mission.new
		@distance = @mission.obtain_farthest
  end

	def create
		@mission = Mission.new(params[:mission])
		@mission.check_and_save
		@distance = @mission.obtain_farthest
		render 'update.js'
	end

	def update
		@mission = Mission.find(params[:id])
		@mission.attributes = params[:mission]
		if @mission.need_check_candidates
			@mission.check_and_save
		else
			@mission.save
		end
		@distance = @mission.obtain_farthest
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

	def destroy
		@mission = Mission.find(params[:id])
		@mission.destroy
		redirect_to root_path
	end

end
