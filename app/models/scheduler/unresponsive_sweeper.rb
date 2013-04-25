class Scheduler::UnresponsiveSweeper
  def initialize(mission, scheduler)
    @mission = mission
    @scheduler = scheduler
  end

  def sms_timeout
    @sms_timeout ||= @mission.organization.sms_timeout.minutes
  end

  def voice_timeout
    @voice_timeout ||= @mission.organization.voice_timeout.minutes
  end

  def max_sms_retries
    @max_sms_retries ||= if @scheduler.has_sms_channels? 
                           @mission.organization.max_sms_retries
                         else
                           0
                         end
  end

  def max_voice_retries
    @max_voice_retries ||= if @scheduler.has_voice_channels?
                             @mission.organization.max_voice_retries
                           else
                             0
                           end
  end

  def unresponsive_candidates
    @mission.candidates_to_call.
      where("last_sms_att IS NULL OR last_sms_att <= ?", sms_timeout.ago).
      where("last_voice_att IS NULL OR last_voice_att <= ?", voice_timeout.ago).
      reject { |c| 
        (c.has_sms? && c.sms_retries < max_sms_retries) ||
        (c.has_voice? && c.voice_retries < max_voice_retries)
      }
  end

  def perform
    # find pending candidates who we have messaged before timeout minutes
    # ago that don't have remaining retries (of any kind) and set them to
    # unresponsive
    unresponsive_candidates.map do |candidate|
      puts "Candidate #{candidate.volunteer.name} is not responding"
      candidate.no_answer!
    end.any?
  end

  def next_deadline
    next_unresponsives = @mission.candidates_to_call.
      where("last_sms_att IS NULL OR sms_retries >= ?", max_sms_retries).
      where("last_voice_att IS NULL OR voice_retries >= ?", max_voice_retries).
      reject { |c| 
        (c.has_sms? && c.sms_retries < max_sms_retries) ||
        (c.has_voice? && c.voice_retries < max_voice_retries)
      }

    next_sms = next_unresponsives.
      reject { |c| c.last_sms_att.nil? }.
      sort_by { |c| c.last_sms_att }.
      first
    next_sms = next_sms.last_sms_att + sms_timeout if next_sms

    next_voice = next_unresponsives.
      reject { |c| c.last_voice_att.nil? }.
      sort_by { |c| c.last_voice_att }.
      first
    next_voice = next_voice.last_voice_att + voice_timeout if next_voice

    if next_sms.nil? || (next_voice && next_sms > next_voice)
      next_voice
    elsif next_voice.nil? || (next_sms && next_voice > next_sms)
      next_sms
    else
      nil
    end
  end
end

