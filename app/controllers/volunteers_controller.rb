class VolunteersController < ApplicationController

	before_filter :authenticate_user!
	
	add_breadcrumb "Volunteers", :volunteers_path

  # GET /volunteers
  # GET /volunteers.xml
  def index
    @volunteers_count = Volunteer.count
    
    @order = params[:order] || 'name'
    @direction = params[:direction] == 'DESC' ? 'DESC' : 'ASC'
    @page = params[:page] || 1
    @volunteers = Volunteer.order("#{@order} #{@direction}").page @page

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @volunteers }
    end
  end

  # GET /volunteers/1
  # GET /volunteers/1.xml
  def show
    @volunteer = Volunteer.find(params[:id])

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

    respond_to do |format|
      if @volunteer.save
        format.html { redirect_to(@volunteer, :notice => 'Volunteer was successfully created.') }
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
    @volunteer = Volunteer.find(params[:id])

    respond_to do |format|
      if @volunteer.update_attributes(params[:volunteer])
        format.html { redirect_to(volunteers_url, :notice => 'Volunteer was successfully updated.') }
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
    @volunteer = Volunteer.find(params[:id])
    @volunteer.destroy

    respond_to do |format|
      format.html { redirect_to(volunteers_url) }
      format.xml  { head :ok }
    end
  end
  
  # POST /volunteers/import
  def import
    VolunteerImporter.new.import params[:file].read
    redirect_to :action => "index"
  end
end
