module VerboiceHelper
  
  def tts message
    URI.escape("http://translate.google.com/translate_tts?tl=en&q=#{message}")
  end
  
end
