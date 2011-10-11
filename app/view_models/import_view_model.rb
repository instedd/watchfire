class ImportViewModel < ViewModel  
  attr_accessor :volunteers
  
  def self.from_model volunteers
    import_view_model = ImportViewModel.new
    import_view_model.volunteers = volunteers.map{|v| VolunteerViewModel.from_model v}
    import_view_model
  end
  
  def volunteers_attributes=(attributes)
    @volunteers = attributes.values.map{|attrs| VolunteerViewModel.new attrs}
  end
  
  def save
    valid = true
    begin
      Volunteer.transaction do
        @volunteers.each do |v|
          raise Exception.new unless v.save
        end
      end
    rescue Exception => e
      valid = false
    end
    valid
  end
  
  def size
    @volunteers.size
  end
  
  def conflicts
    @volunteers.reject{|v| v.valid?}.size
  end
  
  def has_conflicts?
    @volunteers.reject{|v| v.valid?}.size > 0
  end
  
end