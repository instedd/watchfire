require 'uri'

module VerboiceHelper
	
	def ispeech text
		"http://api.ispeech.org/api/rest?apikey=#{ispeech_key}&action=convert&voice=usenglishfemale&text=#{escape(text)}"
	end
	
	def ispeech_available?
		!ispeech_key.blank? rescue false
	end
	
	def gather_options(options={})
		{
			:action => verboice_callback_url,
			:method => 'POST',
			:numDigits => 1,
			:timeout => 15,
			:finishOnKey => ""
		}.merge(options)
	end
	
	private
	
	def ispeech_key
		Watchfire::Application.config.ispeech_api_key
	end
	
	def escape text
		URI.escape(text, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
	end
	
end