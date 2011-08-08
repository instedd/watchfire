require 'spec_helper'

describe VerboiceController do

  describe "GET 'plan'" do
    it "should be successful" do
      get 'plan'
      response.should be_success
    end
  end

end
