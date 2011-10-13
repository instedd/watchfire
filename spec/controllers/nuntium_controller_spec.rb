require 'spec_helper'

describe NuntiumController do

  describe "POST 'receive'" do
    
    before(:each) do
      @config = Watchfire::Application.config
      @candidate = Candidate.make! :status => 'pending', :last_sms_att => 1.hour.ago
			@number = @candidate.volunteer.sms_channels.first.address
      @request.env['HTTP_AUTHORIZATION'] = http_auth(@config.basic_auth_name, @config.basic_auth_pwd)
    end
    
    it "should be successful" do
      post 'receive', :from => "sms://#{@number}", :body => "yes"
      response.should be_success
    end
    
    it "should confirm candidate" do
      Candidate.expects(:find_last_for_sms_number).with(@number).returns(@candidate)
      @candidate.expects(:update_status).with(:confirmed)
      post 'receive', :from => "sms://#{@number}", :body => "yes"
    end
    
    it "should deny candidate" do
      Candidate.expects(:find_last_for_sms_number).with(@number).returns(@candidate)
      @candidate.expects(:update_status).with(:denied)
      post 'receive', :from => "sms://#{@number}", :body => "no"
    end
    
    it "should not modify status if message isn't correct" do
      post 'receive', :from => "sms://#{@number}", :body => "foo"
      
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
      post 'receive', :from => "sms://#{@number}", :body => "foo"
      response.body.should eq(I18n.t :sms_bad_format, :text => "foo")
      response.content_type.should eq("text/plain")
    end
    
    it "should return successful reply when good message" do
      post 'receive', :from => "sms://#{@number}", :body => "yes"
      response.body.should eq(I18n.t :sms_successful)
      response.content_type.should eq("text/plain")
    end
    
  end

end
