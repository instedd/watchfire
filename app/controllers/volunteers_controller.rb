class VolunteersController < ApplicationController

	before_filter :authenticate_user!
	before_filter :store_referer, :only => [:new, :edit, :destroy]
  before_filter :add_volunteers_breadcrumb, :only => [:index, :show, :new, :edit]


  # GET /volunteers
  # GET /volunteers.xml
  def index
    @volunteers_count = current_organization.volunteers.count

    @order = params[:order] || 'name'
    @direction = params[:direction] == 'DESC' ? 'DESC' : 'ASC'
    @page = params[:page] || 1
    @q = params[:q]

    @volunteers = current_organization.volunteers.order("#{@order} #{@direction}")
    @volunteers = @volunteers.where("name like ? OR address like ?", "%#{@q}%", "%#{@q}%") unless @q.blank?
    @volunteers = @volunteers.page @page

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @volunteers }
    end
  end

  # GET /volunteers/1
  # GET /volunteers/1.xml
  def show
    @volunteer = current_organization.volunteers.find(params[:id])

    respond_to do |format|
      format.html { render 'show', :layout => false}
      format.xml  { render :xml => @volunteer }
    end
  end

  # GET /volunteers/new
  # GET /volunteers/new.xml
  def new
    @volunteer = Volunteer.new

    add_breadcrumb 'New', new_volunteer_path

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @volunteer }
    end
  end

  # GET /volunteers/1/edit
  def edit
    @volunteer = Volunteer.find(params[:id])

    add_breadcrumb @volunteer.name, volunteer_path(@volunteer)
  end

  # POST /volunteers
  # POST /volunteers.xml
  def create
    @volunteer = Volunteer.new(params[:volunteer])
    @volunteer.organization_id = current_organization.id

    respond_to do |format|
      if @volunteer.save
        format.html { redirect_to(back, :notice => 'Volunteer was successfully created.') }
        format.xml  { render :xml => @volunteer, :status => :created, :location => @volunteer }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @volunteer.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /volunteers/1
  # PUT /volunteers/1.xml
  def update
    @volunteer = Volunteer.find(current_organization.volunteers.find(params[:id]).id)

    respond_to do |format|
      if @volunteer.update_attributes(params[:volunteer])
        format.html { redirect_to(back, :notice => 'Volunteer was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @volunteer.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /volunteers/1
  # DELETE /volunteers/1.xml
  def destroy
    @volunteer = Volunteer.find(current_organization.volunteers.find(params[:id]).id)
    @volunteer.destroy

    respond_to do |format|
      format.html { redirect_to(back) }
      format.xml  { head :ok }
    end
  end

  # POST /volunteers/import
  def import
    @view_model = ImportViewModel.from_model(VolunteerImporter.new.import(params[:file].read))
  end

  # POST /volunteers/confirm_import
  def confirm_import
    @view_model = ImportViewModel.new(params[:import_view_model])
    if @view_model.save
      redirect_to volunteers_path
    else
      render 'import'
    end
  end

  private

  def store_referer
    session[:return_to] = request.referer
  end

  def back
    session[:return_to] || volunteers_path
  end

  def add_volunteers_breadcrumb
    add_breadcrumb "#{current_organization.name}", organization_path(current_organization) if current_organization
    add_breadcrumb "Volunteers", :volunteers_path
  end
end
