# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Watchfire::Application.initialize!

# Logger
JobLogger = Logger.new(File.join(Rails.root, 'log', 'job.log'))
JobLogger.level = Logger::DEBUG
JobLogger.formatter = Logger::Formatter.new