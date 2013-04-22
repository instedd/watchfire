require File.expand_path('../../../spec_helper', __FILE__)

acceptance_test do
  get "/missions/282"
  login_as "mmuller+9889@manas.com.ar", "3456789"
  i_should_see "Invalid email or password."  
end