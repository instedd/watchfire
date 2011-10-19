require 'spec_helper'

describe VerboiceController do

  describe "POST 'plan'" do
    
    before(:each) do
      @parameters = {:format => 'xml'}
    end
    
    it "should be successful" do
      post 'plan', @parameters
      response.should be_success
    end
    
    it "should render plan" do
      post 'plan', @parameters
      response.should render_template('plan')
    end
    
  end
  
  describe "POST 'callback'" do
    
    before(:each) do
      @candidate = Candidate.make! :status => :pending
      @call = Call.make! :candidate => @candidate
      @parameters = {:CallSid => @call.session_id, :Digits => '1', :format => 'xml'}
    end
    
    it "should be successful" do
      post 'callback', @parameters
      response.should be_success
    end
    
    it "should set candidate status to confirmed if user pressed 1" do
      @parameters[:Digits] = '1'
      Candidate.expects(:find_by_call_session_id).with(@call.session_id).returns(@candidate)
      @candidate.expects(:update_status).with(:confirmed)
      
      post 'callback', @parameters
      
      response.should render_template('callback')
    end
    
    it "should set candidate status to denied if user pressed 2" do
      @parameters[:Digits] = '2'
      Candidate.expects(:find_by_call_session_id).with(@call.session_id).returns(@candidate)
      @candidate.expects(:update_status).with(:denied)
      
      post 'callback', @parameters
      
      response.should render_template('callback')
    end
    
    it "should render plan if bad answer" do
      @parameters[:Digits] = '9'
      
      post 'callback', @parameters
      
      response.should render_template('plan')
      @candidate.reload.is_pending?.should be true
    end
    
  end

end
