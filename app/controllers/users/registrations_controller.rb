class Users::RegistrationsController < Devise::RegistrationsController

	def new
	  redirect_to new_user_session_path
	end

	def create
    not_found
	end
	
	def destroy
    not_found
	end
	
	private
	
	def not_found
    raise ActionController::RoutingError.new('Not Found')
  end

end
