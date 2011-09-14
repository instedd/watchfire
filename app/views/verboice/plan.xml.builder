xml.instruct!
xml.Response do
  xml.Pause(:length => 2)
  # Repeat the gather command 3 times in case the command timeouts
  (1..3).each do 
    xml.Say @candidate.mission.voice_message
    xml.Gather(:action => verboice_callback_url, :method => 'POST', :numDigits => 1, :timeout => 15) do
      xml.Say I18n.t(:voice_confirmation)
    end
  end
end