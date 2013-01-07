class ApplicationController < ActionController::Base
  include BreadcrumbsOnRails::ControllerMixin

  protect_from_forgery

  def current_organization
    current_user.try(:current_organization)
  end
end
