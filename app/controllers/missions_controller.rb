class MissionsController < ApplicationController

	before_filter :authenticate_user!
	before_filter :check_owner, :except => [:create, :new, :index]

  def show
		@distance = @mission.obtain_farthest
  end

	def new
		@mission = Mission.new
		render 'show'
	end

	def index
		@missions = Mission.where(:user_id => current_user.id).order('id DESC')
	end

	def create
		@mission = Mission.new(params[:mission])
		@mission.user = current_user
		@mission.check_and_save
		@distance = @mission.obtain_farthest
		render 'update.js'
	end

	def update
		@mission.attributes = params[:mission]
		if @mission.need_check_candidates
			@mission.check_and_save
		else
			@mission.save
		end
		@distance = @mission.obtain_farthest
	end
	
	def start
	  @mission.call_volunteers
	end
	
	def stop
	  @mission.stop_calling_volunteers
  end
  
  def refresh
		@distance = @mission.obtain_farthest
    respond_to do |format|
      format.html { render 'index' }
      format.js
    end
  end

	def destroy
		@mission.destroy
		redirect_to root_path
	end

	private

	def check_owner
		@mission = Mission.find(params[:id])
		redirect_to missions_path unless @mission.user == current_user
	end

end
