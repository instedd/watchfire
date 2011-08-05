require 'spec_helper'

describe Candidate do
  
  describe "new candidate" do
    before(:each) do
      @candidate = Candidate.new
    end
  
    it "should have 0 retries" do
      @candidate.sms_retries.should == 0
      @candidate.voice_retries.should == 0
    end
    
    it "should be in pending state" do
      @candidate.is_pending?.should be true
    end
    
    it "should have no last sms or voice timestamps" do
      @candidate.last_sms_att.should be nil
      @candidate.last_voice_att.should be nil
    end
  end
end
