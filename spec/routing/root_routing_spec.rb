require "spec_helper"

describe "Root" do
  describe "routing" do

    it "routes to missions#index" do
      get("/").should route_to("missions#index")
    end

  end
end
