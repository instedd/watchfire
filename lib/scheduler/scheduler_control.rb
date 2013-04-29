#!/usr/bin/env ruby

Root = File.expand_path '../../../', __FILE__
ConfigFilePath = "#{Root}/config/settings.yml"
raise Exception, "#{ConfigFilePath} configuration file is missing" unless FileTest.exists?(ConfigFilePath)

RailsEnv = ENV["RAILS_ENV"] || "development"

require 'yaml'
require 'drb/drb'
require 'logger'

module Rails
  def self.logger
    @logger ||= Logger.new(STDOUT)
  end
end

settings = YAML.load_file(ConfigFilePath)[RailsEnv]
uri = settings['scheduler_uri'] || 'druby://localhost:4000'

require File.expand_path 'app/models/scheduler_advisor.rb', Root

unless ARGV.empty?
  SchedulerAdvisor.advisor = DRb::DRbObject.new_with_uri(uri)
  SchedulerAdvisor.advice(*ARGV)
else
  puts "no data to send the scheduler was specified"
end

