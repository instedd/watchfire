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
      voice_numbers = row[2].split('/').map(&:strip) rescue []
      sms_numbers = row[3].split('/').map(&:strip) rescue []
      location = row[4]
      geocoded_location = geocode location

      volunteer = Volunteer.find_by_name(name) || Volunteer.new
      volunteer.organization = @organization
      volunteer.name = name
      volunteer.address = location
      volunteer.lat = geocoded_location.lat
      volunteer.lng = geocoded_location.lng

			volunteer.voice_channels.each{|c| c.mark_for_destruction}
			volunteer.sms_channels.each{|c| c.mark_for_destruction}
			voice_numbers.each{|n| volunteer.voice_channels.build(:address => n)}
			sms_numbers.each{|n| volunteer.sms_channels.build(:address => n)}

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
