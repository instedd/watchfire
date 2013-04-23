#!/usr/bin/env ruby

Root = File.expand_path '../../../', __FILE__
ConfigFilePath = "#{Root}/config/settings.yml"
raise Exception, "#{ConfigFilePath} configuration file is missing" unless FileTest.exists?(ConfigFilePath)

RailsEnv = ENV["RAILS_ENV"] || "development"

require 'eventmachine'
require 'yaml'

module Watchfire
  module Application
    class Config
      def initialize
        @settings = YAML.load_file(ConfigFilePath)[RailsEnv]
      end

      def scheduler_port
        @settings["scheduler_port"] || 4000
      end

      def method_missing(name, *args)
        p @settings
        if @settings.include?(name.to_s)
          @settings[name.to_s]
        else
          super
        end
      end
    end

    def self.config
      @config ||= Config.new
    end
  end
end

require File.expand_path 'app/models/scheduler_advisor.rb', Root

EM.error_handler do |err|
  puts err
  puts err.backtrace.join "\n"
end

EM::run do
  unless ARGV.empty?
    SchedulerAdvisor.send(*ARGV)
    EM.add_timer(0.5) do
      EM.stop_event_loop
    end
  else
    puts "no data to send the scheduler was specified"
    EM.stop
  end
end

