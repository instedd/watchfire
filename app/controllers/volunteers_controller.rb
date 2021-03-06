class VolunteersController < ApplicationController
	before_filter :authenticate_user!
  before_filter :add_volunteers_breadcrumb, :only => [:index, :new, :edit, :create, :update]
  before_filter :default_numbers_params, :only => [:update, :create]

  # GET /volunteers
  # GET /volunteers.xml
  def index
    @volunteers_count = volunteers.count

    @order = params[:order] || 'name'
    @direction = params[:direction] == 'DESC' ? 'DESC' : 'ASC'
    @page = params[:page] || 1
    @q = params[:q]

    @volunteers = volunteers.order("#{@order} #{@direction}")
    if Channel::ADDRESS_REGEX.match(@q)
      @volunteers = @volunteers.joins(:channels).where("channels.address like ?", "%#{@q}%")
    else
      @volunteers = @volunteers.where("name like ? OR address like ?", "%#{@q}%", "%#{@q}%") unless @q.blank?
    end
    @volunteers = @volunteers.page @page

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @volunteers }
    end
  end

  def show
    respond_to do |format|
      format.html { render 'show', :layout => false}
      format.xml  { render :xml => volunteer }
    end
  end

  # GET /volunteers/new
  # GET /volunteers/new.xml
  def new
    add_breadcrumb 'New', new_volunteer_path

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => volunteer }
    end
  end

  # GET /volunteers/1/edit
  def edit
    add_breadcrumb volunteer.name, edit_volunteer_path(volunteer)
  end

  # POST /volunteers
  # POST /volunteers.xml
  def create
    respond_to do |format|
      if volunteer.save
        format.html { redirect_to(volunteers_path, :notice => "#{volunteer.name} was successfully created.") }
        format.xml  { render :xml => volunteer, :status => :created, :location => volunteer }
      else
        format.html {
          add_breadcrumb 'New', new_volunteer_path
          render :action => "new"
        }
        format.xml  { render :xml => volunteer.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /volunteers/1
  # PUT /volunteers/1.xml
  def update
    respond_to do |format|
      if volunteer.update_attributes(params[:volunteer])
        format.html { redirect_to(volunteers_path, :notice => "#{volunteer.name} was successfully updated.") }
        format.xml  { head :ok }
      else
        format.html {
          add_breadcrumb volunteer.name, edit_volunteer_path(volunteer)
          render :action => "edit"
        }
        format.xml  { render :xml => volunteer.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /volunteers/1
  # DELETE /volunteers/1.xml
  def destroy
    volunteer.destroy

    respond_to do |format|
      format.html { redirect_to volunteers_url, :notice => "#{volunteer.name} was deleted." }
      format.xml  { head :ok }
    end
  end

  def delete_all
    current_organization.volunteers.delete_all
    redirect_to volunteers_url
  end

  # POST /volunteers/import
  def import
    if params[:file]
      @view_model = ImportViewModel.from_model(current_organization, VolunteerImporter.new(current_organization).import(params[:file].read))
      if @view_model.size == 0
        return redirect_to volunteers_path, alert: "The file you uploaded appears to be empty"
      end
    else
      redirect_to volunteers_path, alert: "You must choose a file to upload"
    end
  rescue CSV::MalformedCSVError
    redirect_to volunteers_path, alert: "The file you uploaded is not a CSV file"
  end

  # POST /volunteers/confirm_import
  def confirm_import
    @view_model = ImportViewModel.new(current_organization, params[:import_view_model] || {})
    if @view_model.save
      if @view_model.selected > 0
        redirect_to volunteers_path, notice: "#{@view_model.selected} volunteers imported"
      else
        redirect_to volunteers_path, alert: "No volunteers imported"
      end
    else
      render 'import'
    end
  end

  # POST /volunteers/upload
  def upload
    organization = current_user.organizations.find_by_name params[:organization]
    return render nothing: true, status: 400 unless organization

    errors = []
    response = {errors: errors}
    Volunteer.transaction do
      organization.volunteers.delete_all
      volunteers = VolunteerImporter.new(organization).import(request.body.read)
      volunteers.each do |volunteer|
        begin
          volunteer.save!
        rescue Exception => ex
          errors << {name: volunteer.name, error: ex.to_s}
        end
      end
      response[:total_rows] = volunteers.length
    end

    render json: response
  end

  private

  def add_volunteers_breadcrumb
    add_breadcrumb "#{current_organization.name}", organizations_path if current_organization
    add_breadcrumb "Volunteers", :volunteers_path
  end

  def default_numbers_params
    params[:volunteer][:sms_numbers] ||= []
    params[:volunteer][:voice_numbers] ||= []
  end
end
