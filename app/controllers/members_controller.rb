class MembersController < ApplicationController
  before_filter :authenticate_user!

  def index
  end

  def invite
    if params[:email].blank?
      redirect_to members_path, alert: "Email cannot be blank"
    elsif organization_owner?
      case current_user.invite_to(current_organization, params[:email])
      when :invited_existing
        redirect_to members_path, notice: "#{params[:email]} is now a member of #{current_organization.name}"
      when :invited_new
        redirect_to members_path, notice: "Invitation email sent to #{params[:email]}"
      when :already_member
        redirect_to members_path, alert: "#{params[:email]} is already a member of #{current_organization.name}"
      when :already_invited
        redirect_to members_path, alert: "#{params[:email]} was already invited to #{current_organization.name}"
      when :invalid_email
        redirect_to members_path, alert: "#{params[:email]} is not a valid email address"
      when :delivery_error
        redirect_to members_path, alert: "There was an error sending an invitation to #{params[:email]}"
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
