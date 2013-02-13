xml.instruct!
xml.Response do
	if ispeech_available?
		xml.Play ispeech(candidate.response_message)
	else
		xml.Say candidate.response_message
	end
  xml.Hangup
end