require File.expand_path('../../spec/support/blueprints.rb', __FILE__)

class SanMateoFaker
  
  include Geokit::Geocoders
  
  Center = Geokit::LatLng.new(37.520619,-122.342377)
  Radius = 5
  Bounds = Geokit::Bounds.from_point_and_radius(Center, Radius)
  
  def self.fake n, organization
    1.upto(n).each do
      location = random_location
      Volunteer.make! :lat => location.lat, :lng => location.lng, :address => address(location), :organization => organization
    end
  end
  
  private
  
  def self.random_location
    max_lat = Bounds.ne.lat
    min_lat = Bounds.sw.lat
    max_lng = Bounds.ne.lng
    min_lng = Bounds.sw.lng
    
    lat_length = (max_lat - min_lat).abs
    lng_length = (max_lng - min_lng).abs
    
    lat = rand * lat_length + min_lat
    lng = rand * lng_length + min_lng
    
    Geokit::LatLng.new lat, lng
  end
  
  def self.address lat_lng
    GoogleGeocoder.reverse_geocode(lat_lng).full_address
  end
  
end
