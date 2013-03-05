class MissionsController < ApplicationController
	before_filter :authenticate_user!
  before_filter :add_missions_breadcrumb, :only => [:index, :new, :show]

  def show
    add_breadcrumb mission.name, mission_path(mission)
  end

	def new
	  add_breadcrumb "New", :new_mission_path
    mission.add_mission_skill

		render 'show'
	end

	def index
	end

	def create
		mission.user = current_user
    mission.organization = current_organization
		mission.check_and_save
		render 'update.js'
	end

	def update
		mission.attributes = params[:mission]
		if mission.check_for_volunteers?
			mission.check_and_save
		else
			mission.save
		end
    if params[:new_skill] && mission.valid?
      mission.add_mission_skill
    end
	end

	def start
	  mission.call_volunteers
	end

	def stop
	  mission.stop_calling_volunteers
  end

  def refresh
    respond_to do |format|
      format.html { render 'show' }
      format.js
    end
  end

  def finish
    mission.finish
    render 'show'
  end

  def open
    mission.open
    render 'show'
  end

	def destroy
		mission.destroy
		redirect_to missions_url
	end

	def export
		csv = VolunteerExporter.export mission
		send_data csv, :type => 'text/csv', :filename => "#{mission.name}_results.csv"
	end

	def update_message
	  mission.update_attributes params[:mission]
  end

  def check_all
    mission.enable_all_pending
    render 'update_pending'
  end

  def uncheck_all
    mission.disable_all_pending
    render 'update_pending'
  end

	private

  def add_missions_breadcrumb
    add_breadcrumb "#{current_organization.name}", organizations_path if current_organization
    add_breadcrumb "Events", :missions_path
  end
end
