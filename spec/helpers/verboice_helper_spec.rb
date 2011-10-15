require 'spec_helper'

describe VerboiceHelper do
	it "should tell if ispeech is available" do
		Watchfire::Application.config.ispeech_api_key = nil
		ispeech_available?.should be_false
		Watchfire::Application.config.ispeech_api_key = ''
		ispeech_available?.should be_false
		Watchfire::Application.config.ispeech_api_key = 'an api key'
		ispeech_available?.should be_true
	end
end