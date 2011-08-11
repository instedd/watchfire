xml.instruct!
xml.Response do
  xml.Say "This is a request for an emergency"
  xml.Gather(:action => 'http://localhost:3001/verboice/callback', :method => 'POST', :numDigits => 1) do
    xml.Play tts("Press 1 if you are available or 2 if you are not")
  end
end