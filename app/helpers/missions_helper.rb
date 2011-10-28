module MissionsHelper
  def progress_percentage mission
    "width: #{mission.progress * 100}%;"
  end
  
  def sms_number candidate
    if candidate.answered_from
      enabled = candidate.answered_from == candidate.volunteer.sms_number
    else
      enabled = candidate.active
    end
    content_tag :span, candidate.volunteer.sms_number, :class => enabled ? "mobile" : "gmobile"
  end
  
  def voice_number candidate
    if candidate.answered_from
      enabled = candidate.answered_from == candidate.volunteer.voice_number 
    else
      enabled = candidate.active
    end
    content_tag :span, candidate.volunteer.voice_number, :class => enabled ? "phone" : "gphone"
  end
  
  def time_ago(time)
    content_tag :span, :class => "time", :title => time.iso8601 do
      time.to_s
    end
  end
end
