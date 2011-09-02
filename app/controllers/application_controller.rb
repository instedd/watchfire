class ApplicationController < ActionController::Base
  protect_from_forgery

	def app_config
		Watchfire::Application.config
	end
end
