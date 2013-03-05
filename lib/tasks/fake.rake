desc "Creates fake data"

namespace :fake do
  
  desc "Fake data for San Mateo County"
  #task :san_mateo, :n, :needs => :environment do |t, args|
  task :san_mateo, [:n, :organization_name] => :environment  do |t, args|
    require 'san_mateo_faker'
    args.with_defaults(:n => 100)
    args.with_defaults(:organization_name => Organization.first.name)
    organization = Organization.find_by_name(args.organization_name)
    if organization
      print "Faking #{args.n} volunteers for organization #{organization.name}..."
      SanMateoFaker.fake args.n.to_i, organization
      puts "Done"
    else
      puts "Cannot find organization #{args.organization_name}"
    end
  end

end

