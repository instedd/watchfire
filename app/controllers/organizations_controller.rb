class OrganizationsController < ApplicationController
  before_filter :authenticate_user!

  add_breadcrumb "Organizations", :organizations_path

  def index
    @organizations = current_user.organizations.all
    @organization = Organization.new
  end

  def new
    @organization = Organization.new
  end

  def create
    @organization = Organization.new(params[:organization])
    if current_user.create_organization(@organization)
      redirect_to organizations_path, :notice => 'Organization was successfully created'
    else
      render :action => "new"
    end
  end

  def edit
    @organization = current_user.organizations.find params[:id]
    @owner = current_user.owner_of?(@organization)
    redirect_to :show unless @owner
  end

  def update
    @organization = Organization.find current_user.organizations.find(params[:id]).id
    @owner = current_user.owner_of?(@organization)
    redirect_to :show unless @owner

    if @organization.update_attributes(params[:organization])
      redirect_to organization_path(@organization), :notice => 'Organization was successfully updated'
    else
      render :action => "edit"
    end
  end

  def select
    organization = current_user.organizations.find params[:id]
    current_user.current_organization_id = organization.id
    current_user.save!

    redirect_to missions_path
  end
end
