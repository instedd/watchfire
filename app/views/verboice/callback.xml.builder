xml.instruct!
xml.Response do
	if ispeech_available?
		xml.Play ispeech(I18n.t(:voice_successful))
	else
		xml.Say I18n.t(:voice_successful)
	end
  xml.Hangup
end