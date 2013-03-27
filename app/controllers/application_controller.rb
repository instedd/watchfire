class ApplicationController < ActionController::Base
  protect_from_forgery

  expose(:current_organization) { current_user.try(:current_organization) }

  expose(:missions) { current_organization ? current_organization.missions.order('id desc') : Mission.none }
  expose(:mission)

  expose(:volunteers) { current_organization ? current_organization.volunteers : Volunteer.none }
  expose(:volunteer)

  expose(:members) { current_organization ? current_organization.members.includes(:user) : Member.none }

  expose(:organization_owner?) { current_user && current_organization && current_user.owner_of?(current_organization) }

  expose(:skills) { current_organization ? current_organization.skills : Skill.none }

  expose(:pigeon_channels) { current_organization ? current_organization.pigeon_channels.order('name') : PigeonChannel.none }
end
