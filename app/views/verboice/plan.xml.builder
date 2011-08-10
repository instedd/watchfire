xml.instruct!
xml.Response do
  xml.Play tts("This is a request for an emergency")
  xml.Gather(:action => 'http://190.18.54.215:55777/verboice/callback', :method => 'POST', :numDigits => 1) do
    xml.Play tts("Press 1 if you are available or 2 if you are not")
  end
end