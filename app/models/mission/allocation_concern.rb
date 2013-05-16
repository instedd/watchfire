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

    def allocate_one(volunteer = nil)
      slot = @slots.find do |slot| 
        slot[:risk] >= 0 && 
          slot[:needed] > slot[:allocated].size && 
          (volunteer ||= select_volunteer(slot[:skill])) &&
          (slot[:skill].nil? || 
           volunteer.skills.include?(slot[:skill]))
      end
      if slot && volunteer
        slot[:allocated] << volunteer
        slot
      else
        nil
      end
    end

    def run
      Hash[run_all]
    end

    def run_all
      begin
        recompute_risks
      end while allocate_one
      @slots.map do |slot|
        slot_output(slot) 
      end
    end

    def run_once
      recompute_risks
      slot_output(allocate_one)
    end

    def run_for(volunteer)
      recompute_risks
      slot_output(allocate_one(volunteer))
    end

    def calculate_risks
      recompute_risks
      Hash[@slots.map do |slot|
        [slot[:skill].try(:id), slot[:risk]]
      end]
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
    vols = vols.select { |v| v.available_at? Time.now.utc }
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

  def pending_allocation_by_risk
    # allocate pending volunteers
    algo_pending = RiskBasedAlgorithm.new(pending_volunteers)
    mission_skills.each do |ms|
      still_needed = ms.still_needed / available_ratio
      algo_pending.add_requirement ms.skill, still_needed
    end
    risks = algo_pending.calculate_risks
    allocation = algo_pending.run_all
    allocation = allocation.sort_by { |slot| -risks[slot.first] }

    # add remaining (not allocated) volunteers to the last (least
    # riskiest skill)
    allocation.last.second.concat(algo_pending.pool)
    allocation
  end

  def obtain_initial_volunteers
    initial_allocation.values.flatten
  end

  def obtain_more_volunteers
    incremental_allocation.values.flatten
  end

  def preferred_skill_for_candidate(candidate)
    algo = RiskBasedAlgorithm.new(pending_volunteers)
    mission_skills.each do |ms|
      still_needed = ms.still_needed / available_ratio
      algo.add_requirement ms.skill, still_needed
    end
    skill_id, allocated = algo.run_for(candidate.volunteer)
    skill_id && candidate.volunteer.skills.find do |skill|
      skill.id == skill_id
    end
  end

  def all_requirements_fulfilled?
    mission_skills.all? { |ms| ms.still_needed <= 0 }
  end

  def check_for_more_volunteers
    if all_requirements_fulfilled?
      finish
    else
      new_volunteers = obtain_more_volunteers

      unless new_volunteers.empty?
        Mission.transaction do
          new_volunteers.each do |v|
            add_volunteer v
          end
        end
        self.candidates.reload
      end

      if candidates_to_call.empty?
        stop_calling_volunteers
      end
    end
    self.save! if self.changed?
  end

  def max_distance
    Watchfire::Application.config.max_distance
  end

  def available_ratio
    Watchfire::Application.config.available_ratio
  end

end

