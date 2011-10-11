class VolunteerViewModel < ViewModel
  attr_accessor :volunteer
  attr_accessor :selected
  
  def initialize(attributes = {})
    @volunteer = attributes[:id] ? Volunteer.find(attributes[:id]) : Volunteer.new
    super
  end
  
  def self.from_model volunteer
    volunteer_view_model = VolunteerViewModel.new
    volunteer_view_model.volunteer = volunteer
    volunteer_view_model.selected = true
    volunteer_view_model
  end
  
  def save
    selected ? @volunteer.save : true
  end
  
  def strategy
    @strategy.to_sym
  end
  
  def selected
    if @selected.class == String
      @selected == "1"
    else
      @selected
    end
  end
  
  private
  
  def method_missing(method, *args, &block)
    @volunteer.send(method, *args, &block)
  end
  
end