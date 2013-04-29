# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'mocha/setup'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  # config.mock_with :rspec

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  config.before(:each) do
    Timecop.return
    SchedulerAdvisor.advisor = nil
  end

  # Returns the string to be used for HTTP_AUTHENTICATION header
  def http_auth(user, pass)
    'Basic ' + Base64.encode64(user + ':' + pass)
  end

  def push_scheduler_advisor(advisor = mock)
    raise RuntimeError, "advisor already pushed" if @old_advisor
    @old_advisor = SchedulerAdvisor.advisor
    SchedulerAdvisor.advisor = advisor
    advisor
  end

  def pop_scheduler_advisor
    SchedulerAdvisor.advisor = @old_advisor
    @old_advisor = nil
  end

  # Include Devise helpers
  config.include Devise::TestHelpers, :type => :controller
end
