class MissionsController < ApplicationController
  def index
    @mission = Mission.first || Mission.new
  end

end
