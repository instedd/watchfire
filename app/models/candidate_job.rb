class CandidateJob < Struct.new(:candidate_id)
  def enqueue(job)
    candidate = Candidate.find(candidate_id)
    MissionJob.create! :mission => candidate.mission, :job => job
  end
end