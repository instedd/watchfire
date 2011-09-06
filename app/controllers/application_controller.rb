class ApplicationController < ActionController::Base
  include BreadcrumbsOnRails::ControllerMixin
  
  protect_from_forgery
end
