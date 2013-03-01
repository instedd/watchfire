module MissionsHelper
  def progress_percentage mission
    "width: #{mission.progress * 100}%;"
  end

  def sms_numbers candidate, sep=$,
    sep ||= tag :br
    if candidate.answered_from
      enabled = candidate.volunteer.has_sms_number?(candidate.answered_from)
    else
      enabled = candidate.active
    end
    safe_join(candidate.volunteer.sms_channels.map { |channel|
      content_tag :span, channel.address, :class => enabled ? "mobile" : "gmobile"
    }, sep)
  end

  def voice_numbers candidate, sep=$,
    sep ||= tag :br
    if candidate.answered_from
      enabled = candidate.volunteer.has_voice_number?(candidate.answered_from)
    else
      enabled = candidate.active
    end
    current_voice_number = nil
    if candidate.voice_status && candidate.status == :pending
      current_voice_number = candidate.last_call.voice_number
    end
    safe_join(candidate.volunteer.voice_channels.map { |channel|
      content = channel.address
      if channel.address == current_voice_number
        content = "#{content} (#{candidate.voice_status})"
      end
      content_tag :span, content, :class => enabled ? "phone" : "gphone"
    }, sep)
  end

  def time_ago(time)
    content_tag :span, :class => "time", :title => time.iso8601 do
      time.to_s
    end
  end
end
