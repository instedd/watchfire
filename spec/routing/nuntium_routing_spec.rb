require "spec_helper"

describe NuntiumController do
  describe "routing" do

    it "routes to #receive" do
      post("/nuntium/receive").should route_to("nuntium#receive")
    end
    
  end
end
