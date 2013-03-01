require 'spec_helper'

describe NuntiumController do

  describe "POST 'receive'" do
    
    before(:each) do
      @config = Watchfire::Application.config
      @candidate = Candidate.make! :status => 'pending', :last_sms_att => 1.hour.ago
      @sms_number = @candidate.volunteer.sms_channels.first.address
      @request.env['HTTP_AUTHORIZATION'] = http_auth(@config.basic_auth_name, @config.basic_auth_pwd)
    end
    
    it "should be successful" do
      post 'receive', :from => "sms://#{@sms_number}", :body => "yes"
      response.should be_success
    end
    
    it "should confirm candidate" do
      Candidate.expects(:find_last_for_sms_number).with(@sms_number).returns(@candidate)
      @candidate.expects(:answered_from_sms!).with("yes", @sms_number)
      post 'receive', :from => "sms://#{@sms_number}", :body => "yes"
    end
    
    it "should deny candidate" do
      Candidate.expects(:find_last_for_sms_number).with(@sms_number).returns(@candidate)
      @candidate.expects(:answered_from_sms!).with("no", @sms_number)
      post 'receive', :from => "sms://#{@sms_number}", :body => "no"
    end
    
    it "should not modify status if message isn't correct" do
      post 'receive', :from => "sms://#{@sms_number}", :body => "foo"
      
      @candidate.reload.is_pending?.should be true
    end
    
    it "should not update status if candidate is unresponsive" do
      unresponsive_candidate = Candidate.make! :status => 'unresponsive', :last_sms_att => 1.hour.ago

      post 'receive', :from => "sms://#{unresponsive_candidate.volunteer.sms_channels.first.address}", :body => "yes"
      
      unresponsive_candidate.reload.is_unresponsive?.should be true
    end
    
    it "should fail with no auth" do
      @request.env['HTTP_AUTHORIZATION'] = nil
      post 'receive'
      response.status.should be(401)
    end
    
    it "should fail with incorrect auth" do
      @request.env['HTTP_AUTHORIZATION'] = http_auth 'foo', 'bar'
      post 'receive'
      response.status.should be(401)
    end
    
    it "should return not undestood reply when bad message" do
      post 'receive', :from => "sms://#{@sms_number}", :body => "foo"
      response.body.should eq(I18n.t :sms_bad_format, :text => "foo")
      response.content_type.should eq("text/plain")
    end
    
    it "should return confirmed message reply when user confirms" do
      post 'receive', :from => "sms://#{@sms_number}", :body => "yes"
      response.body.should eq(I18n.t :response_confirmed)
      response.content_type.should eq("text/plain")
    end
    
    it "should return denied message reply when user denies" do
      post 'receive', :from => "sms://#{@sms_number}", :body => "no"
      response.body.should eq(I18n.t :response_denied)
      response.content_type.should eq("text/plain")
    end

    it "should confirm candidate with capitalized text" do
      Candidate.expects(:find_last_for_sms_number).with(@sms_number).returns(@candidate)
      @candidate.expects(:answered_from_sms!).with("yes", @sms_number)
      post 'receive', :from => @sms_number.with_protocol, :body => "Yes"
    end
    
    it "should deny candidate with capitalized text" do
      Candidate.expects(:find_last_for_sms_number).with(@sms_number).returns(@candidate)
      @candidate.expects(:answered_from_sms!).with("no", @sms_number)
      post 'receive', :from => @sms_number.with_protocol, :body => "No"
    end
    
    ["Yes I Can!", "I think I will be available, yes"].each do |answer|
      it "should allow more flexible responses for confirmation" do
        Candidate.expects(:find_last_for_sms_number).with(@sms_number).returns(@candidate)
        @candidate.expects(:answered_from_sms!).with("yes", @sms_number)
        post 'receive', :from => @sms_number.with_protocol, :body => answer
      end
    end
    
    ["No I can't!", "Sorry no I won't be available"].each do |answer|
      it "should allow more flexible responses for denial" do
        Candidate.expects(:find_last_for_sms_number).with(@sms_number).returns(@candidate)
        @candidate.expects(:answered_from_sms!).with("no", @sms_number)
        post 'receive', :from => @sms_number.with_protocol, :body => answer
      end
    end
    
  end

end
