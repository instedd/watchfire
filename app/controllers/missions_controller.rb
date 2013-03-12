class MissionsController < ApplicationController
	before_filter :authenticate_user!
  before_filter :add_missions_breadcrumb, :only => [:index, :new, :show]

  expose(:mission_json) {
    candidates = mission.candidates_with_channels.map { |candidate| 
      result = candidate.as_json(
        :only => [:id, :active, :answered_at, :answered_from, :status, :voice_status],
        :include => {
          :volunteer => { 
            :only => [:id, :name, :lat, :lng],
            :include => {
              :sms_channels => { :only => :address },
              :voice_channels => { :only => :address }
            }
          }
        }
      )["candidate"]
      if candidate.voice_status && candidate.status == :pending
        result["last_call"] = candidate.last_call.as_json['call']
      end
      result
    }

    mission.as_json(:include => {
      :mission_skills => { 
        :only => [:id, :req_vols, :skill_id, :priority] 
      }
    }).
    deep_merge({ 
      :errors => mission.errors, 
      "mission" => { 
        "farthest" => mission.farthest,
        "total_req_vols" => mission.total_req_vols,
        "confirmed_count" => mission.candidate_count(:confirmed),
        "progress" => mission.progress,
        "candidates" => candidates
      },
      :urls => mission.new_record? ? {
        :update => missions_path 
      } : {
        :update => mission_path(mission),
        :start => start_mission_path(mission),
        :stop => stop_mission_path(mission),
        :open => open_mission_path(mission),
        :check_all => check_all_mission_path(mission),
        :uncheck_all => uncheck_all_mission_path(mission),
        :export => export_mission_path(mission)
      }
    })
  }

  def show
    respond_to do |format|
      format.html {
        add_breadcrumb mission.name, mission_path(mission)
        render 'koshow'
      }
      format.json { 
        render :json => mission_json
      }
    end
  end

	def new
	  add_breadcrumb "New", :new_mission_path
    mission.add_mission_skill

		render 'koshow'
	end

	def index
	end

	def create
		mission.user = current_user
    mission.organization = current_organization
		mission.check_and_save
    respond_to do |format|
      format.html { render 'update.js' }
      format.json {
        render :json => mission_json
      }
    end
	end

	def update
		if mission.check_for_volunteers?
			mission.check_and_save
		else
			mission.save
		end
    respond_to do |format|
      format.js
      format.json {
        render :json => mission_json
      }
    end
	end

	def start
	  mission.call_volunteers
    respond_to do |format|
      format.js
      format.json {
        render :json => mission_json
      }
    end
	end

	def stop
	  mission.stop_calling_volunteers
    respond_to do |format|
      format.js
      format.json {
        render :json => mission_json
      }
    end
  end

  def refresh
    respond_to do |format|
      format.html { render 'koshow' }
      format.js
    end
  end

  def finish
    mission.finish
    render 'koshow'
  end

  def open
    mission.open
    render 'koshow'
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
    respond_to do |format|
      format.js {
        render 'update_pending'
      }
      format.json {
        render :json => mission_json
      }
    end
  end

  def uncheck_all
    mission.disable_all_pending
    respond_to do |format|
      format.js {
        render 'update_pending'
      }
      format.json {
        render :json => mission_json
      }
    end
  end

	private

  def add_missions_breadcrumb
    add_breadcrumb "#{current_organization.name}", organizations_path if current_organization
    add_breadcrumb "Events", :missions_path
  end
end
