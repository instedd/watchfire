require "spec_helper"

describe CandidatesController do
  describe "routing" do

    it "routes to #update" do
      put("/candidates/1").should route_to("candidates#update", :id => "1")
    end
    
  end
end
