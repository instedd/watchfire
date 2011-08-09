class MissionsController < ApplicationController
  def index
    @mission = Mission.first || Mission.new
  end

	def create
		@mission = Mission.new(params[:mission])
		@distance = @mission.check_and_save
	end

	def update
		@mission = Mission.find(params[:id])
		@mission.attributes = params[:mission]
		@distance = @mission.check_and_save
	end

end
