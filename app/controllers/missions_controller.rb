class MissionsController < ApplicationController
  
  add_breadcrumb "Events", :missions_path

	before_filter :authenticate_user!
	before_filter :check_owner, :except => [:create, :new, :index]

  def show
    add_breadcrumb @mission.reason, mission_path(@mission)
  end

	def new
	  @mission = Mission.new
	  
	  add_breadcrumb "New", :new_mission_path
		
		render 'show'
	end

	def index
		@missions = Mission.where(:user_id => current_user.id).order('id DESC')
	end

	def create
		@mission = Mission.new(params[:mission])
		@mission.user = current_user
		@mission.check_and_save
		render 'update.js'
	end

	def update
		@mission.attributes = params[:mission]
		if @mission.check_for_volunteers?
			@mission.check_and_save
		else
			@mission.save
		end
	end
	
	def start
	  @mission.call_volunteers
	end
	
	def stop
	  @mission.stop_calling_volunteers
  end
  
  def refresh
    respond_to do |format|
      format.html { render 'show' }
      format.js
    end
  end
  
  def finish
    @mission.finish
    render 'show'
  end
  
  def open
    @mission.open
    render 'show'
  end

	def destroy
		@mission.destroy
		redirect_to missions_url
	end
	
	def clone
	  @mission = @mission.new_duplicate
	  render 'show'
  end

	def export
		csv = VolunteerExporter.export @mission
		send_data csv, :type => 'text/csv', :filename => "#{@mission.name}_results.csv"
	end

	private

	def check_owner
		@mission = Mission.find(params[:id])
		redirect_to missions_path unless @mission.user == current_user
	end

end
