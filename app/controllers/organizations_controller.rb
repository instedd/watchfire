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

  def show
    @organization = current_user.organizations.find params[:id]
    @owner = current_user.owner_of?(@organization)
    add_breadcrumb @organization.name, organization_path(@organization)
  end

  def select
    organization = current_user.organizations.find params[:id]
    current_user.current_organization_id = organization.id
    current_user.save!

    redirect_to missions_path
  end

  def invite_user
    organization = current_user.organizations.find params[:id]
    if current_user.owner_of?(organization)
      existing = current_user.invite_to organization, params[:email]

      if existing
        redirect_to organization_path(organization), notice: "#{params[:email]} is now a member of #{organization.name}"
      else
        redirect_to organization_path(organization), notice: "Invitation email sent to #{params[:email]}"
      end
    else
      redirect_to organization_path(organization), alert: "You can't invite users because are not an owner of #{organization.name}"
    end
  end
end
