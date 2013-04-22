require File.expand_path('../../../spec_helper', __FILE__)

acceptance_test do
  event = unique('event')
  get "/"
  login_as "mmuller+9889@manas.com.ar", "123456789"
  create_event :name => event, :volunteers_quantity => "4",:description => "a single house fire. 3 pets.", :address => "san mateo"
  sleep 5
  @driver.find_element(:xpath, "//div[contains(@id, 'mission_status')]/button").click
  sleep 4
  i_should_see "Resume recruiting" 
end
