require File.expand_path('../../../spec_helper', __FILE__)

acceptance_test do
  get "/"
  login_as "mmuller+9889@manas.com.ar", "123456789"
  i_should_see "Signed in successfully."
end