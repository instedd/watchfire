class Users::RegistrationsController < Devise::RegistrationsController

	def new
		redirect_to new_user_session_path
	end

	def create
		raise
	end

end
