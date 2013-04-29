# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'mocha/setup'
require 'capybara/rspec'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}
Dir[Rails.root.join("spec/integration/spec/helpers/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #

  ###########
  #capybara
  config.include Warden::Test::Helpers
  config.include Capybara::DSL,           example_group: { file_path: config.escaped_path(%w[spec integration])}
  config.include Capybara::CustomFinders, example_group: { file_path: config.escaped_path(%w[spec integration])}
  config.include Capybara::AccountHelper, example_group: { file_path: config.escaped_path(%w[spec integration])}
  config.include Capybara::EventHelper, example_group: { file_path: config.escaped_path(%w[spec integration])}
  config.filter_run_excluding(js: true)   unless config.filter_manager.inclusions[:js]

  Warden.test_mode!
  
  Capybara.default_wait_time = 5
  Capybara.javascript_driver = :selenium
  Capybara.default_selector = :css

  config.before :each do
    DatabaseCleaner.strategy = if Capybara.current_driver == :rack_test
      :transaction
    else
      [:truncation]
    end
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end
  ##########

  config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  # config.mock_with :rspec

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  config.before(:each) do
    Timecop.return
  end

  # Returns the string to be used for HTTP_AUTHENTICATION header
  def http_auth(user, pass)
    'Basic ' + Base64.encode64(user + ':' + pass)
  end

  # Include Devise helpers
  config.include Devise::TestHelpers, :type => :controller
end
