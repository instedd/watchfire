require "spec_helper"

describe MissionsController do
  describe "routing" do

    it "routes to #index" do
      get("/missions").should route_to("missions#index")
    end

    it "routes to #new" do
      get("/missions/new").should route_to("missions#new")
    end

    it "routes to #show" do
      get("/missions/1").should route_to("missions#show", :id => "1")
    end

    it "routes to #edit" do
      get("/missions/1/edit").should route_to("missions#edit", :id => "1")
    end

    it "routes to #create" do
      post("/missions").should route_to("missions#create")
    end

    it "routes to #update" do
      put("/missions/1").should route_to("missions#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/missions/1").should route_to("missions#destroy", :id => "1")
    end
    
    it "routes to #start" do
      post("/missions/1/start").should route_to("missions#start", :id => "1")
    end
    
    it "routes to #stop" do
      post("/missions/1/stop").should route_to("missions#stop", :id => "1")
    end
    
    it "routes to #finish" do
      post("/missions/1/finish").should route_to("missions#finish", :id => "1")
    end
    
    it "routes to #open" do
      post("/missions/1/open").should route_to("missions#open", :id => "1")
    end
    
    it "routes to #refresh" do
      get("/missions/1/refresh").should route_to("missions#refresh", :id => "1")
    end
    
		it "routes to #export" do
      get("/missions/1/export").should route_to("missions#export", :id => "1")
    end
    
    it "routes to #check_all" do
      post("/missions/1/check_all").should route_to("missions#check_all", :id => "1")
    end
    
    it "routes to #uncheck_all" do
      post("/missions/1/uncheck_all").should route_to("missions#uncheck_all", :id => "1")
    end
  end
end
