class	Nuntium
	
	def self.from_config
		config = Watchfire::Application.config
		Nuntium.new config.nuntium_host, config.nuntium_account, config.nuntium_app, config.nuntium_app_passwd
	end
	
end