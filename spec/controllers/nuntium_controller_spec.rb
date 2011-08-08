require 'spec_helper'

describe NuntiumController do

  describe "POST 'receive'" do
    
    before(:each) do
      @candidate = Candidate.make! :status => 'pending', :last_sms_att => 1.hour.ago
    end
    
    it "should be successful" do
      post 'receive', :from => "sms://#{@candidate.volunteer.sms_number}", :body => "1"
      response.should be_success
    end
    
    it "should confirm candidate" do
      post 'receive', :from => "sms://#{@candidate.volunteer.sms_number}", :body => "1"
      
      @candidate.reload.is_confirmed?.should be true
    end
    
    it "should deny candidate" do
      post 'receive', :from => "sms://#{@candidate.volunteer.sms_number}", :body => "2"
      
      @candidate.reload.is_denied?.should be true
    end
    
    it "should not modify status if message isn't correct" do
      post 'receive', :from => "sms://#{@candidate.volunteer.sms_number}", :body => "foo"
      
      @candidate.reload.is_pending?.should be true
    end
    
    it "should not update status if candidate is unresponsive" do
      unresponsive_candidate = Candidate.make! :status => 'unresponsive', :last_sms_att => 1.hour.ago

      post 'receive', :from => "sms://#{unresponsive_candidate.volunteer.sms_number}", :body => "1"
      
      unresponsive_candidate.reload.is_unresponsive?.should be true
    end
    
  end

end
