require 'spec_helper'

describe Volunteer do
  
  before(:each) do
    @volunteer = Volunteer.new
		@valid_attributes = {:name => "name", :lat => 10, :lng => 20, :address => "address", :sms_channels => [SmsChannel.make]}
  end
  
  describe "availability" do
    it "should be available by default" do
      Day.all.each do |day|
        (0..23).each do |hour|
          @volunteer.available?(day, hour).should be true
        end 
      end
    end
    
    it "should tell availability" do
      set_unavailable Day.tuesday, 10
      @volunteer.available?(Day.tuesday, 10).should be false
      set_available Day.tuesday, 10
      @volunteer.available?(Day.tuesday, 10).should be true
    end
    
    it "should tell availability by time" do
      time = Time.utc(2011,9,1,10,34,50)
      set_unavailable Day.thursday, 10
      @volunteer.available_at?(time).should be false
      set_available Day.thursday, 10
      @volunteer.available_at?(time).should be true
    end
    
    def set_available day, hour
      @volunteer.shifts = @volunteer.shifts || {}
      @volunteer.shifts[day.to_s] = @volunteer.shifts[day.to_s] || {}
      @volunteer.shifts[day.to_s][hour.to_s] = "1"
    end
    
    def set_unavailable day, hour
      @volunteer.shifts = @volunteer.shifts || {}
      @volunteer.shifts[day.to_s] = @volunteer.shifts[day.to_s] || {}
      @volunteer.shifts[day.to_s][hour.to_s] = "0"
    end
  end

	describe "valid" do
		it "should be valid with valid attributes" do
			@volunteer.attributes = @valid_attributes
			@volunteer.valid?.should be_true
		end
		
		it "should be invalid with no channels" do
			@volunteer.attributes = @valid_attributes.except(:sms_channels)
			@volunteer.valid?.should be_false
		end
		
		it "should be invalid without name" do
			@volunteer.attributes = @valid_attributes.except(:name)
			@volunteer.valid?.should be_false
		end
	end
  
end
