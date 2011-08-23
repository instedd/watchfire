desc "Creates fake data"

namespace :fake do
  
  desc "Fake data for San Mateo County"
  #task :san_mateo, :n, :needs => :environment do |t, args|
  task :san_mateo, [:n]  => :environment  do |t, args|
    require 'san_mateo_faker'
    args.with_defaults(:n => 100)
    print "Faking #{args.n} volunteers..."
    SanMateoFaker.fake args.n.to_i
    puts "Done"
  end

end

