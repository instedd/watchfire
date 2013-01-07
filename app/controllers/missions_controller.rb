class MissionsController < ApplicationController
	before_filter :authenticate_user!
  before_filter :check_has_organizations
	before_filter :check_owner, :except => [:create, :new, :index]
  before_filter :add_missions_breadcrumb, :only => [:index, :new, :show]

  def show
    add_breadcrumb @mission.name, mission_path(@mission)
  end

	def new
	  @mission = Mission.new

	  add_breadcrumb "New", :new_mission_path

		render 'show'
	end

	def index
		@missions = Mission.where(:organization_id => current_organization.id, :user_id => current_user.id).order('id DESC')
	end

	def create
		@mission = Mission.new(params[:mission])
		@mission.user = current_user
    @mission.organization = current_organization
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

	def update_message
	  @mission.update_attributes params[:mission]
  end

  def check_all
    @mission.enable_all_pending
    render 'update_pending'
  end

  def uncheck_all
    @mission.disable_all_pending
    render 'update_pending'
  end

	private

	def check_owner
		@mission = Mission.find(params[:id])
		redirect_to missions_path unless @mission.user == current_user && @mission.organization == current_organization
	end

  def check_has_organizations
    redirect_to organizations_path unless current_user.has_organizations?
  end

  def add_missions_breadcrumb
    add_breadcrumb "#{current_organization.name}", organization_path(current_organization) if current_organization
    add_breadcrumb "Events", :missions_path
  end
end
