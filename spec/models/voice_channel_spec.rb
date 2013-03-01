require 'spec_helper'

describe VoiceChannel do
	before(:each) do
		@channel = VoiceChannel.new
		@valid_attributes = {:address => "123", :volunteer => Volunteer.new}
	end
	
	it "should be valid with valid attributes" do
		@channel.attributes = @valid_attributes
		@channel.valid?.should be_true
	end
	
  it "should have an address" do
		@channel.attributes = @valid_attributes.except(:address)
		@channel.valid?.should be_false
	end
	
	it "should have a volunteer" do
		@channel.attributes = @valid_attributes.except(:volunteer)
		@channel.valid?.should be_false
	end
end
