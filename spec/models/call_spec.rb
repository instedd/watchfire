require 'spec_helper'

describe Call do
  before :each do
		@call = Call.new
		@valid_attributes = {:session_id => "session", :candidate => Candidate.new}
	end
	
	it "should be valid with valid attributes" do
		@call.attributes = @valid_attributes
		@call.valid?.should be_true
	end
	
	[:session_id, :candidate].each do |attr|
		it "should be invalid without #{attr}" do
			@call.attributes = @valid_attributes.except(attr)
			@call.valid?.should be_false
		end
	end
end
