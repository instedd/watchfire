require 'csv'

class VolunteerImporter

  include Geokit::Geocoders

  def initialize(organization)
    @organization = organization
    @geocode_cache = {}
  end

  def import content, options = {}
    volunteers = []
    columns = nil

    CSV.parse(content, col_sep: CSV.guess_column_separator(content)) do |row|
      unless columns
        columns = parse_header row
      else
        volunteer = parse_row row, columns, options[:default_location]
        volunteers << volunteer unless volunteer.nil?
      end
    end
    volunteers
  end

  def parse_header header
    columns = {}
    header.each_with_index do |col, i|
      case col
      when /name/i then columns[:name] = i
      when /address/i then columns[:address] = i
      when /lat/i then columns[:lat] = i
      when /lng/i then columns[:lng] = i
      when /skills/i, /roles/i then columns[:skills] = i
      when /sms/i
        (columns[:sms] ||= []) << i
      when /voice/i, /phone/i
        (columns[:voice] ||= []) << i
      when /avail_(\w+)_(\d\d)00/
        (columns[:shifts] ||= {})[[$1, $2.to_i]] = i
      end
    end
    columns
  end

  # name, roles, voice_phone, sms_phone, location
  def parse_row row, columns, default_location = nil
    begin
      volunteer = if columns.has_key?(:name)
        name = row[columns[:name]]
        Volunteer.find_by_name(name) || Volunteer.new(name: name)
      end || Volunteer.new
      volunteer.organization = @organization

      if columns[:address]
        volunteer.address = row[columns[:address]]

        if columns.has_key?(:lat) && columns.has_key?(:lng)
          volunteer.lat = Float(row[columns[:lat]]) rescue nil
          volunteer.lng = Float(row[columns[:lng]].to_f) rescue nil
        end

        unless volunteer.lat && volunteer.lng
          geocoded_location = geocode volunteer.address
          volunteer.lat = geocoded_location.lat
          volunteer.lng = geocoded_location.lng
        end
      end

      # delete existing phones
      volunteer.voice_channels.each{|c| c.mark_for_destruction}
      volunteer.sms_channels.each{|c| c.mark_for_destruction}

      if columns.has_key?(:voice)
        columns[:voice].each do |i|
          numbers = split(row[i], '/')
          numbers.each { |n| volunteer.voice_channels.build(address: n) }
        end
      end

      if columns.has_key?(:sms)
        columns[:sms].each do |i|
          numbers = split(row[i], '/')
          numbers.each { |n| volunteer.sms_channels.build(address: n) }
        end
      end

      if columns.has_key?(:skills)
        skills = split(row[columns[:skills]], /[|\/]/)
        volunteer.skills = skills.map do |skill_name|
          Skill.find_or_create_by_organization_id_and_name(@organization.id, skill_name)
        end
      end

      if columns.has_key?(:shifts)
        # load default shifts
        volunteer.shifts = shifts = {}
        Day.all.each do |day|
          shift_day = shifts[day.to_s] = {}
          (0..23).each do |hour|
            shift_day[hour.to_s] = "0"
          end
        end

        columns[:shifts].each do |key, i|
          day, hour = key
          shifts[day.to_s][hour.to_s] = (row[i] && ["1", "true"].include?(row[i].downcase) ? "1" : "0")
        end
      end


      volunteer
    # rescue Exception => e
    #   nil
    end
  end

  def split(cell, pattern)
    return [] unless cell.present?
    cell.split(pattern).map(&:strip)
  end

  def geocode location
    @geocode_cache[location] ||= GoogleGeocoder3.geocode(location)
  end
end
