if ispeech_available?
  sentences = message.sentences
  last_sentence = sentences.pop
  sentences.each do |sentence|
    xml.Gather(gather_options(:timeout => 0, :action => url)) do
      xml.Play ispeech(sentence)
    end
    xml.Pause(:length => 1)
  end
  xml.Gather(gather_options(:action => url)) do
    xml.Play ispeech(last_sentence)
  end
else
  xml.Gather(gather_options(:action => url)) do
    xml.Say message
  end
end
