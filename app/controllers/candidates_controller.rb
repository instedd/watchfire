class CandidatesController < ApplicationController

	def update
		@candidate = Candidate.find(params[:id])
		@candidate.update_attributes(params[:candidate])
		@mission = @candidate.mission
	end
end

