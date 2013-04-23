# Performs a run of sending SMSs to all pending candidates that still
# have remaining SMS retries
#
class Scheduler::SmsSender
  def initialize(mission)
    @mission = mission
  end

  def max_sms_retries
    @max_sms_retries ||= @mission.organization.max_sms_retries
  end

  def sms_timeout
    @sms_timeout ||= @mission.organization.sms_timeout.minutes
  end

  def find_candidates_to_sms
    @mission.candidates.
      where(:status => :pending).
      where("last_sms_att IS NULL OR last_sms_att < ?", sms_timeout.ago)
      where("sms_retries < ?", max_sms_retries).
      includes(:volunteer => [:sms_channels])
  end

  def send_sms_to_candidate(candidate)
    volunteer = candidate.volunteer
    puts "Sending SMS to #{volunteer.name} at #{volunteer.sms_numbers}"

    candidate.sms_retries += 1
    candidate.last_sms_att = Time.now.utc
    candidate.save :validate => false
  end

  def perform
    # find pending candidates who still have SMS retries and that we have
    # never messaged or we have messaged before timeout minutes ago
    candidates = find_candidates_to_sms
    
    # for each of those candidates, send an SMS to all registered SMS
    # numbers, decrement the number of retries remaining and set the last
    # SMS attempt timestamp
    candidates.each do |candidate|
      send_sms_to_candidate(candidate)
    end
  end

  def calculate_next_time
    # get the time at which we should perform a new SMS send
    older = @mission.candidates.where(:status => :pending).
      order("last_sms_att ASC").first
    if older
      if older.last_sms_att.nil?
        Time.now
      else
        older.last_sms_att.in sms_timeout
      end
    else
      nil
    end
  end
end

