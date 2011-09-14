xml.instruct!
xml.Response do
  xml.Pause(:length => 2)
  xml.Say @candidate.mission.voice_message
  xml.Gather(:action => verboice_callback_url, :method => 'POST', :numDigits => 1, :timeout => 15) do
    xml.Say I18n.t(:voice_confirmation)
  end
end