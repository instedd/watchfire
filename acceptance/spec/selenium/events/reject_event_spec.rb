require File.expand_path('../../../spec_helper', __FILE__)

acceptance_test do
  event = unique('RejectedEvent')
  get "/"
  login_as "mmuller+9889@manas.com.ar", "123456789"
  create_event :name => event, :volunteers_quantity => "4",:description => "a single house fire. 3 pets.", :address => "san mateo"
  answer_call
  reply "no"
  sleep 5
  i_should_see "Denied"
end

