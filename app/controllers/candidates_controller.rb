class CandidatesController < ApplicationController
  expose(:candidate) { Candidate.find(params[:id]) }
  expose(:mission) { candidate.mission }

	def update
		candidate.update_attributes(params[:candidate])
	end
end

