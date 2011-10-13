xml.instruct!
xml.Response do
  xml.Pause(:length => 2)
  # Repeat the gather command 3 times in case the command timeouts
  3.times do 
    xml.Gather(:action => verboice_callback_url, :method => 'POST', :numDigits => 1, :timeout => 15, :finishOnKey => "") do
			xml.Say @candidate.mission.voice_message
    end
  end
end