class ImportViewModel < ViewModel
  attr_accessor :volunteers

  def self.from_model(organization, volunteers)
    import_view_model = ImportViewModel.new(organization)
    import_view_model.volunteers = volunteers.map{|v| VolunteerViewModel.from_model v}
    import_view_model
  end

  def initialize(organization, attributes = {})
    @organization = organization
    @volunteers = []
    super(attributes)
  end

  def volunteers_attributes=(attributes)
    @volunteers = attributes.values.map do |attrs|
      VolunteerViewModel.new attrs.merge({organization_id: @organization.id})
    end
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

  def selected
    @volunteers.select{|v| v.selected}.size
  end

end
