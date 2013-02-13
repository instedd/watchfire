class MembersController < ApplicationController
  before_filter :authenticate_user!

  def index
  end

  def invite
    if organization_owner?
      existing = current_user.invite_to current_organization, params[:email]

      if existing
        redirect_to members_path, notice: "#{params[:email]} is now a member of #{current_organization.name}"
      else
        redirect_to members_path, notice: "Invitation email sent to #{params[:email]}"
      end
    else
      redirect_to members_path, alert: "You can't invite users because are not an owner of #{current_organization.name}"
    end
  end

  def accept_invite
    invite = Invite.where(token: params[:token]).first
    if invite
      current_user.join invite.organization
      invite.destroy
      redirect_to missions_path, alert: "You are now member of #{current_organization.name}"
    else
      redirect_to missions_path, alert: "The invitation has already been accepted by you or someone else"
    end
  end
end