xml.instruct!
xml.Response do
  xml.Pause(:length => 2)
  2.times do
    xml << render(partial: 'voice_message', locals: {message: candidate.mission.voice_before_confirmation_message, url: verboice_after_confirmation_url})
  end
end
