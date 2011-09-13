require "spec_helper"

describe VerboiceController do
  describe "routing" do

    it "routes to #plan" do
      post("/verboice/plan").should route_to("verboice#plan", :format => 'xml')
    end
    
    it "routes to #callback" do
      post("/verboice/callback").should route_to("verboice#callback", :format => 'xml')
    end
    
  end
end
