xml.instruct!
xml.Response do
  xml.Say @candidate.mission.voice_message
  xml.Gather(:action => verboice_callback_url, :method => 'POST', :numDigits => 1) do
    xml.Say  I18n.t(:voice_confirmation)
  end
end