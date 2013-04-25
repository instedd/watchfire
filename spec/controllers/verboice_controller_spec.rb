require 'spec_helper'

describe VerboiceController do
  describe "POST 'plan'" do
    before(:each) do
      @session_id = '123'
      @parameters = {:format => 'xml', :CallSid => @session_id}
      @candidate = Candidate.make
      @current_call = CurrentCall.make candidate: @candidate, session_id: @session_id
      CurrentCall.expects(:find_by_session_id).with(@session_id).returns(@current_call)
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

  describe "POST 'plan' with forward" do
    before(:each) do
      @parameters = {:format => 'xml', :CallSid => '1234', :From => '555', :Channel => 'foo' }
      @organization = Organization.make!
      @mission = Mission.make! :forward_address => '111', :organization => @organization, :status => :running
    end

    context "calling number is known" do
      it "should forward to the mission that made the last call to the number" do
        @candidate = Candidate.make! :mission => @mission
        @call = Call.make! :voice_number => @parameters[:From], :candidate => @candidate
        post 'plan', @parameters
        response.should render_template('plan_forward')
        assigns(:mission).should eq(@mission)
      end
    end

    context "calling number is unknown" do
      context "channel is unknown" do
        it "should forward to the latest running mission" do
          post 'plan', @parameters
          response.should render_template('plan_forward')
          assigns(:mission).should eq(@mission)
        end
      end

      context "channel is known" do
        it "should forward to the organization's running mission launched last" do
          @channel = PigeonChannel.make! :channel_type => :verboice, :pigeon_name => @parameters[:Channel], :organization => @organization

          post 'plan', @parameters
          response.should render_template('plan_forward')
          assigns(:mission).should eq(@mission)
        end
      end

      it "should hang up when there are no running missions" do
        @mission.update_attribute :status, :pending

        post 'plan', @parameters
        response.should render_template('plan_forward')
        assigns(:mission).should be_nil
      end

      it "should hang up if the last running mission does not have a forward address" do 
        @mission.update_attribute :forward_address, nil

        post 'plan', @parameters
        response.should render_template('plan_forward')
        assigns(:mission).should be_nil
      end
    end
  end

  describe "POST 'plan_after_confirmation'" do
    before(:each) do
      @session_id = '123'
      @parameters = {:format => 'xml', :CallSid => @session_id}
      @current_call = CurrentCall.make! session_id: @session_id
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
      @call = CurrentCall.make :candidate => @candidate
      @parameters = {:CallSid => @call.session_id, :Digits => '1', :format => 'xml'}
      CurrentCall.expects(:find_by_session_id).with(@call.session_id).returns(@call)
    end

    it "should be successful" do
      post 'callback', @parameters
      response.should be_success
    end

    it "should set candidate status to confirmed if user pressed 1" do
      @parameters[:Digits] = "1"
      @candidate.expects(:answered_from_voice!).with("1", @call.voice_number)

      post 'callback', @parameters

      response.should render_template('callback')
    end

    it "should set candidate status to denied if user pressed 2" do
      @parameters[:Digits] = "2"
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
      @call = CurrentCall.make! :candidate => @candidate
      @parameters = {:CallSid => @call.session_id, :Digits => '1', :CallStatus => 'ringing'}
      @advisor = push_scheduler_advisor
      @advisor.expects(:call_status_update).with(@call.session_id, 'ringing')
    end

    after(:each) do
      pop_scheduler_advisor
    end

    it "should be successful" do
      get 'status_callback', @parameters
      response.should be_success
    end

    it "should set candidate voice status" do
      get 'status_callback', @parameters
      @candidate.reload.last_call_status.should eq('ringing')
    end
  end
end
