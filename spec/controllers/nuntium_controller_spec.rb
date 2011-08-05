require 'spec_helper'

describe NuntiumController do

  describe "GET 'receive'" do
    it "should be successful" do
      get 'receive'
      response.should be_success
    end
  end

end
