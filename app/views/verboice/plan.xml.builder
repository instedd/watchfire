xml.instruct!
xml.Response do
  xml.Pause(:length => 2)
  # Repeat the gather command 3 times in case the command timeouts
  3.times do
		if ispeech_available?
			sentences = @candidate.mission.voice_message_sentences
			last_sentence = sentences.pop
			sentences.each do |sentence|
				xml.Gather(gather_options(:timeout => 0)) do
					xml.Play ispeech(sentence)
				end
				xml.Pause(:length => 1)
			end
			xml.Gather(gather_options) do
				xml.Play ispeech(last_sentence)
			end
		else
			xml.Gather(gather_options) do
				xml.Say @candidate.mission.voice_message
			end
		end
  end
end