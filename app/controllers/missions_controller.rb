class MissionsController < ApplicationController
  def index
		vol1 = Volunteer.new(:name => 'v1', :voice_number => '11', :sms_number => 's11')
		vol2 = Volunteer.new(:name => 'v2', :voice_number => '22')
		vol3 = Volunteer.new(:name => 'v3', :sms_number => 's11')
		vol4 = Volunteer.new(:name => 'v4', :voice_number => '44', :sms_number => 's11')
		
		c1 = Candidate.new(:status => :pending, :volunteer => vol1)
		c2 = Candidate.new(:status => :confirmed, :volunteer => vol2)
		c3 = Candidate.new(:status => :denied, :volunteer => vol3)
		c4 = Candidate.new(:status => :unresponsive, :volunteer => vol4)

    @mission = Mission.first || Mission.new
		@mission.candidates = [c1, c2, c3, c4]
  end

end
