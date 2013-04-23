#!/usr/bin/env ruby

ENV["RAILS_ENV"] = ARGV[0] unless ARGV.empty?
$log_path = File.expand_path '../../../log/scheduler.log', __FILE__

require(File.expand_path '../../../config/boot.rb', __FILE__)
require(File.expand_path '../../../config/environment.rb', __FILE__)

Rails.logger = Logger.new(STDOUT) if STDOUT.tty?

EM.error_handler do |err|
  puts err
  puts err.backtrace.join "\n"
end

EM::run do
  EM.schedule do
    Scheduler.start
    puts 'Ready'
  end
end

