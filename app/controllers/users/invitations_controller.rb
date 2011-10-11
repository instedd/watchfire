class Users::InvitationsController < Devise::InvitationsController
	def after_invite_path_for(resource)
		params[:next] || super
	end
end
