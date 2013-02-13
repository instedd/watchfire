require 'spec_helper'

describe CandidatesController do
  before :each do
    @candidate = Candidate.make!
  end

  describe "update" do
    it "updates the requested candidate" do
      Candidate.expects(:find).with(@candidate.id.to_s).returns(@candidate)
      @candidate.expects(:update_attributes).with({'foo' => 'bar'})
      put :update, :id => @candidate.id.to_s, :format => 'js', :candidate => {'foo' => 'bar'}
    end

    it "assigns the requested candidate" do
      put :update, :id => @candidate.id.to_s, :format => 'js'
      controller.candidate.should eq(@candidate)
    end

    it "assigns the mission of the requested candidate" do
      put :update, :id => @candidate.id.to_s, :format => 'js'
      controller.mission.should eq(@candidate.mission)
    end

    it "renders update template" do
      put :update, :id => @candidate.id.to_s, :format => 'js'
      response.should render_template('update')
    end
  end
end