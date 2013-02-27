require 'csv'

class VolunteerImporter

  include Geokit::Geocoders

  def initialize(organization)
    @organization = organization
    @geocode_cache = {}
  end

  def import content, options = {}
    volunteers = []
    CSV.parse(content, col_sep: CSV.guess_column_separator(content), headers: content.start_with?('#')) do |row|
      volunteer = parse_row row, options[:default_location]
      volunteers << volunteer unless volunteer.nil?
    end
    volunteers
  end

  private

  # name, roles, voice_phone, sms_phone, location
  def parse_row row, default_location
    begin
      name = row[0]
      roles = row[1].split('/').map(&:strip) rescue []
      voice_phone = row[2]
      sms_phone = row[3]
      location = row[4]
      geocoded_location = geocode location

      volunteer = Volunteer.find_by_name(name) || Volunteer.new
      volunteer.organization = @organization
      volunteer.name = name
      volunteer.voice_number = voice_phone
      volunteer.sms_number = sms_phone
      volunteer.address = location
      volunteer.lat = geocoded_location.lat
      volunteer.lng = geocoded_location.lng
      volunteer.skills = roles.map{|n| Skill.find_or_create_by_organization_id_and_name(@organization.id, n)}
      volunteer
    rescue Exception => e
      nil
    end
  end

  def geocode location
    @geocode_cache[location] = GoogleGeocoder.geocode(location) unless @geocode_cache[location]
    @geocode_cache[location]
  end

end
