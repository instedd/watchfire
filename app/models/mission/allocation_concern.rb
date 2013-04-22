module Mission::AllocationConcern
  extend ActiveSupport::Concern

  class RiskBasedAlgorithm
    attr_accessor :pool, :slots

    def initialize pool = []
      @pool = pool
      @slots = []
    end

    def add_requirement(skill, needed)
      @slots << { 
        skill: skill, 
        needed: needed, 
        available: 0, 
        risk: -1, 
        allocated: [] 
      }
    end

    def select_volunteer(skill = nil)
      index = @pool.find_index do |v|
        skill.nil? || v.skills.include?(skill)
      end
      index && @pool.delete_at(index)
    end

    def allocate_one
      volunteer = nil
      slot = @slots.find do |slot| 
        slot[:risk] >= 0 && 
          slot[:needed] > slot[:allocated].size && 
          (volunteer = select_volunteer(slot[:skill]))
      end
      if slot && volunteer
        slot[:allocated] << volunteer
        slot
      else
        nil
      end
    end

    def run
      begin
        recompute_risks
      end while allocate_one

      Hash[@slots.map do |slot| slot_output(slot) end]
    end

    def run_once
      recompute_risks
      Hash[slot_output(allocate_one)]
    end

  private

    def slot_output(slot)
      slot && [slot[:skill].try(:id), slot[:allocated]]
    end

    def recompute_risks
      compute_available
      compute_risks
    end

    def compute_available
      available_skills = @pool.map(&:skills).flatten.map(&:id)
      @slots.each do |slot|
        skill_id = slot[:skill].try(:id)
        unless skill_id
          slot[:available] = @pool.size
        else
          slot[:available] = available_skills.select { |sid| sid == skill_id }.size
        end
      end
    end

    def compute_risks
      @slots.each do |slot|
        still_needed = slot[:needed] - slot[:allocated].size
        available = slot[:available]
        slot[:risk] = if available > 0 && still_needed > 0
          if slot[:skill]
            still_needed / available.to_f
          else
            # make sure non-skilled requirements are the least risky
            0
          end
        else
          -1
        end
      end
      @slots = @slots.sort_by { |slot| -slot[:risk] }
    end

  end


  def obtain_volunteer_pool(rejected = [])
    required_skill_ids = mission_skills.map(&:skill_id)
    vols = Volunteer.where(:organization_id => organization_id).
      geo_scope(:origin => self, :within => max_distance).
      includes(:skills)
    if !required_skill_ids.include?(nil)
      vols = vols.where('skills_volunteers.skill_id' => required_skill_ids)
    end
    unless rejected.empty?
      rejected = Set.new rejected
      vols = vols.reject { |v| rejected.include?(v) }
    end
    vols.sort_by_distance_from(self)
  end

  def initial_allocation
    algo = RiskBasedAlgorithm.new(obtain_volunteer_pool)
    mission_skills.each do |ms|
      algo.add_requirement ms.skill, ms.req_vols / available_ratio
    end
    algo.run
  end

  def pending_volunteers
    self.candidates.where(:status => :pending).map(&:volunteer)
  end

  def incremental_allocation
    # allocate pending volunteers
    algo_pending = RiskBasedAlgorithm.new(pending_volunteers)
    mission_skills.each do |ms|
      still_needed = ms.still_needed / available_ratio
      algo_pending.add_requirement ms.skill, still_needed
    end
    pending_allocations = algo_pending.run
    
    # now run again against a new pool of volunteers to try to fill in the
    # remaining pending slots
    algo_incremental = RiskBasedAlgorithm.new(obtain_volunteer_pool(volunteers))
    mission_skills.each do |ms|
      still_needed = ms.still_needed / available_ratio
      still_needed -= pending_allocations[ms.skill_id].size
      algo_incremental.add_requirement ms.skill, still_needed
    end
    algo_incremental.run
  end

  def obtain_initial_volunteers
    initial_allocation.values.flatten
  end

  def obtain_more_volunteers
    incremental_allocation.values.flatten
  end

  def allocate_confirmed_candidate(candidate)

  end

  # OBSOLETE
  def obtain_volunteers
    vols = []
    mission_skills.each do |mission_skill|
      mission_skill.mission = self  # needed to successfully call obtain_volunteers
      num_vols = (mission_skill.req_vols / available_ratio).to_i
      vols = vols + mission_skill.obtain_volunteers(num_vols, vols)
    end
    vols
  end

  def allocate_candidates confirmed, pending
    # go through each mission skill by priority and check if we got the desired
    # number of volunteers for each by allocating confirmed and pending
    # candidates
    mission_skills.map do |mission_skill|
      data = { :mission_skill => mission_skill }

      data[:confirmed] = mission_skill.claim_candidates confirmed
      confirmed = confirmed - data[:confirmed]

      if data[:confirmed].size < mission_skill.req_vols
        data[:needed] = ((mission_skill.req_vols - data[:confirmed].size) / available_ratio).to_i
        data[:pending] = mission_skill.claim_candidates pending, data[:needed]
        pending = pending - data[:pending]
      else
        data[:pending] = []
        data[:needed] = 0
      end

      data
    end
  end

  def candidate_allocation_order
    # by default, candidates are ordered by the number of skills the volunteer
    # posses, so less specialized volunteers are allocated first
    Proc.new do |c1, c2|
      c1.volunteer.skills.size <=> c2.volunteer.skills.size
    end
  end

  def check_for_more_volunteers
    # allocate the confirmed and pending candidates to the required skills for
    # the mission
    pending = pending_candidates.sort(&candidate_allocation_order)
    confirmed = confirmed_candidates.sort(&candidate_allocation_order)
    allocation = allocate_candidates(confirmed, pending)

    # for each mission skill with allocated candidates, check if we need to add
    # new volunteers to fulfill the required number
    finished = true
    allocation.each do |data|
      if data[:needed] > 0
        if data[:pending].size < data[:needed]
          # not enough number of volunteers in the pending pool that can
          # fulfill this skill requirement
          recruit = data[:needed] - data[:pending].size
          # find new volunteers for this skill
          new_volunteers = data[:mission_skill].obtain_volunteers recruit, self.volunteers
          Mission.transaction do
            new_volunteers.each {|v| add_volunteer v}
          end
          self.candidates.reload
        end
        # we're not done yet
        finished = false
      end
    end

		finish if finished
		self.save! if self.changed?
  end

  def max_distance
    Watchfire::Application.config.max_distance
  end

  def available_ratio
    Watchfire::Application.config.available_ratio
  end

end

