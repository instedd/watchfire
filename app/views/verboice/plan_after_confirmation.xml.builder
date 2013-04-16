xml.instruct!
xml.Response do
  xml.Pause(:length => 2)
  3.times do
    xml << render(partial: 'voice_message', locals: {message: candidate.mission.voice_after_confirmation_message, url: verboice_callback_url})
  end
end
