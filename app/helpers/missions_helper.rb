module MissionsHelper
  def progress_percentage mission
    "width: #{mission.progress * 100}%;"
  end

  def sms_numbers candidate
    if candidate.answered_from
      enabled = candidate.answered_from == candidate.volunteer.sms_channels.address
    else
      enabled = candidate.active
    end
    candidate.volunteer.sms_channels.map { |channel|
      content_tag :span, channel.address, :class => enabled ? "mobile" : "gmobile"
    }.reduce(:+)
  end

  def voice_numbers candidate
    if candidate.answered_from
      enabled = candidate.answered_from == candidate.volunteer.voice_channels.first.address
    else
      enabled = candidate.active
    end
    content = candidate.volunteer.voice_channels.first.address
    if candidate.voice_status && candidate.status == :pending
      content = "#{content} (#{candidate.voice_status})"
    end
    # FIXME: show voice status next to current number
    candidate.volunteer.voice_channels.map { |channel|
      content_tag :span, channel.address, :class => enabled ? "phone" : "gphone"
    }.reduce(:+)
  end

  def time_ago(time)
    content_tag :span, :class => "time", :title => time.iso8601 do
      time.to_s
    end
  end
end
