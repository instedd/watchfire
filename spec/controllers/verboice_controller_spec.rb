require 'spec_helper'

describe VerboiceController do
  describe "POST 'plan'" do
    before(:each) do
      @parameters = {:format => 'xml', :CallSid => '123'}
      @candidate = Candidate.make
      Candidate.expects(:find_by_call_session_id).with('123').returns(@candidate)
    end

    it "should be successful" do
      post 'plan', @parameters
      response.should be_success
    end

    it "should render plan_no_confirmation if mission should not confirm human" do
      @candidate.mission.expects(:confirm_human?).returns(false)
      post 'plan', @parameters
      response.should render_template('plan_no_confirmation')
    end

    it "should render plan_before_confirmation if mission should confirm human" do
      @candidate.mission.expects(:confirm_human?).returns(true)
      post 'plan', @parameters
      response.should render_template('plan_before_confirmation')
    end
  end

  describe "POST 'plan_after_confirmation'" do
    before(:each) do
      @parameters = {:format => 'xml'}
    end

    it "should be successful" do
      post 'plan_after_confirmation', @parameters
      response.should be_success
    end

    it "should render after_confirmation" do
      post 'plan_after_confirmation', @parameters
      response.should render_template('plan_after_confirmation')
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
      @parameters[:Digits] = "1"
      Candidate.expects(:find_by_call_session_id).with(@call.session_id).returns(@candidate)
      @candidate.expects(:answered_from_voice!).with("1", @call.voice_number)

      post 'callback', @parameters

      response.should render_template('callback')
    end

    it "should set candidate status to denied if user pressed 2" do
      @parameters[:Digits] = "2"
      Candidate.expects(:find_by_call_session_id).with(@call.session_id).returns(@candidate)
      @candidate.expects(:answered_from_voice!).with("2", @call.voice_number)

      post 'callback', @parameters

      response.should render_template('callback')
    end

    it "should render plan_no_confirmation if bad answer" do
      @parameters[:Digits] = '9'

      post 'callback', @parameters

      response.should render_template('plan_no_confirmation')
      @candidate.reload.is_pending?.should be true
    end
  end

  describe "GET 'status_callback'" do
    before(:each) do
      @candidate = Candidate.make! :status => :pending
      @call = Call.make! :candidate => @candidate
      @parameters = {:CallSid => @call.session_id, :Digits => '1', :CallStatus => 'ringing'}
    end

    it "should be successful" do
      get 'status_callback', @parameters
      response.should be_success
    end

    it "should set candidate voice status" do
      get 'status_callback', @parameters
      @candidate.reload.voice_status.should eq('ringing')
    end
  end
end
