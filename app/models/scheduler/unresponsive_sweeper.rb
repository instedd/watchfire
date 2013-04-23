class Scheduler::UnresponsiveSweeper
  def initialize(mission)
    @mission = mission
  end

  def max_sms_retries
    @max_sms_retries ||= @mission.organization.max_sms_retries
  end

  def max_voice_retries
    @max_voice_retries ||= @mission.organization.max_voice_retries
  end

  def sms_timeout
    @sms_timeout ||= @mission.organization.sms_timeout.minutes
  end

  def voice_timeout
    @voice_timeout ||= @mission.organization.voice_timeout.minutes
  end

  def unresponsive_candidates
    @mission.candidates.
      where(:status => :pending).
      where("last_sms_att IS NULL OR last_sms_att < ?", sms_timeout.ago)
      where("last_voice_att IS NULL OR last_voice_att < ?", voice_timeout.ago)
      where("sms_retries >= ?", max_sms_retries).
      where("voice_retries >= ?", max_voice_retries)
  end

  def perform
    # find pending candidates who we have messaged before timeout minutes
    # ago that don't have remaining retries (of any kind) and set them to
    # unresponsive
    unresponsive_candidates.map do |candidate|
      candidate.no_answer!
    end.any?
  end
end

