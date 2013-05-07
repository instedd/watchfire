require 'spec_helper'

describe Scheduler::CallPlacer do
  before(:each) do
    @organization = Organization.make!
    @scheduler = mock
    @scheduler.stubs(:organization).returns(@organization)
    @placer = Scheduler::CallPlacer.new(@scheduler)
  end

  def make_mission(params = {})
    Mission.make!({ 
      organization: @organization, 
      status: :running,
      lat: 37, lng: -122
    }.merge(params))
  end

  describe "missions_by_latest_voice_attempt" do
    before(:each) do
      @m1 = make_mission
      @m2 = make_mission
      @cm1 = Candidate.make! mission: @m1, last_voice_att: 2.minutes.ago
      @cm2 = Candidate.make! mission: @m2, last_voice_att: 5.minutes.ago
    end

    it "should return missions ordered by latest voice attempt" do
      @placer.missions_by_latest_voice_attempt.should eq([@m2, @m1])
    end

    it "should only return active missions" do
      @m2.update_attribute :status, :pending

      @placer.missions_by_latest_voice_attempt.should_not include(@m2)
    end
  end

  describe "find_next_volunteer_to_call" do
    before(:each) do
      @mission = make_mission
    end

    def make_candidate(params = {})
      Candidate.make!({ mission: @mission, status: :pending }.merge(params))
    end

    it "should only return active pending candidates" do
      @candidate = make_candidate active: false
      @placer.find_next_volunteer_to_call.should be_nil

      @candidate.update_attribute :active, true
      @placer.find_next_volunteer_to_call.should eq(@candidate)

      @candidate.update_attribute :status, :denied
      @placer.find_next_volunteer_to_call.should be_nil
    end

    it "should return candidates with voice numbers" do
      @volunteer = Volunteer.make!(organization: @organization, voice_channels: [])
      @candidate = make_candidate volunteer: @volunteer
      @placer.find_next_volunteer_to_call.should be_nil

      @volunteer.voice_channels << VoiceChannel.make
      @volunteer.save!
      @placer.find_next_volunteer_to_call.should eq(@candidate)
    end

    it "should return candidates with voice retries left" do
      @candidate = make_candidate voice_retries: 1
      @placer.find_next_volunteer_to_call.should eq(@candidate)

      @candidate.update_attribute :voice_retries, @organization.max_voice_retries
      @placer.find_next_volunteer_to_call.should be_nil
    end

    it "should return candidates with expired voice timeout" do
      @candidate = make_candidate voice_retries: 1, last_voice_att: 1.minute.ago
      @candidate.update_attribute :last_voice_number, @candidate.volunteer.ordered_voice_numbers.last
      @placer.find_next_volunteer_to_call.should be_nil

      Timecop.travel(@organization.voice_timeout.minutes)
      @placer.find_next_volunteer_to_call.should eq(@candidate)
    end

    describe "candidates have multiple voice numbers" do
      before(:each) do
        @volunteer = Volunteer.make! voice_channels: 
          [VoiceChannel.make, VoiceChannel.make]
        @first_number = @volunteer.ordered_voice_numbers.first
        @last_number = @volunteer.ordered_voice_numbers.last
        @candidate = make_candidate volunteer: @volunteer, 
          last_voice_number: @first_number, last_voice_att: 1.minute.ago
      end

      it "when last number called is not the last voice number should not wait for timeout" do
        @placer.find_next_volunteer_to_call.should eq(@candidate)

        @candidate.update_attribute :last_voice_number, @last_number
        @placer.find_next_volunteer_to_call.should be_nil
      end
    end

    def make_candidate(params = {})
      location = params.delete(:location) || @mission.endpoint(0,0)
      lat = location.lat
      lng = location.lng
      skills = params.delete(:skills) || []
      volunteer = Volunteer.make! organization: @organization, 
        lat: lat, lng: lng, skills: skills
      Candidate.make!({ mission: @mission, volunteer: volunteer }.merge(params))
    end

    it "should return nearest candidates first" do
      @at1 = @mission.endpoint(0,1)
      @at2 = @mission.endpoint(0,2)
      @c1 = make_candidate location: @at1
      @c2 = make_candidate location: @at2

      @placer.find_next_volunteer_to_call.should eq(@c1)
    end

    it "should return candidates for the riskiest skill first" do
      @skill = Skill.make! organization: @organization

      @c1 = make_candidate location: @mission.endpoint(0,1)
      @c2 = make_candidate location: @mission.endpoint(0,2), skills: [@skill]

      @placer.find_next_volunteer_to_call.should eq(@c1)
      @mission.add_mission_skill skill: @skill
      @mission.save!
      @placer.find_next_volunteer_to_call.should eq(@c2)
    end

  end

  describe "place_call" do
    before(:each) do
      @channel = PigeonChannel.make!(:verboice, organization: @organization)
      @mission = make_mission
      @candidate = Candidate.make! mission: @mission

      @verboice = mock
      Verboice.stubs(:from_config).returns(@verboice)
      @verboice.stubs(:call).returns({ 'call_id' => '1234', 'state' => 'queued' })
    end

    it "should enqueue a call with Verboice" do
      @verboice.unstub(:call)
      number = @candidate.next_number_to_call
      @verboice.expects(:call).with(number, { 
        :status_callback_url => @placer.status_callback_url, 
        :channel => @channel.pigeon_name 
      }).returns({ 
        'call_id' => '1234', 'state' => 'queued' 
      })
      @placer.place_call @candidate, @channel
    end

    it "should create a new current call" do
      lambda do
        @placer.place_call @candidate, @channel 
      end.should change(CurrentCall, :count).by(1)

      call = @channel.current_calls.first
      call.candidate.should eq(@candidate)
      call.session_id.should eq('1234')
      call.call_status.should eq('queued')
    end

    it "should set last voice attempt and last voice number" do
      Timecop.freeze

      @placer.place_call @candidate, @channel

      @candidate.last_voice_att.should eq(Time.now)
      @candidate.last_voice_number.should eq(@candidate.volunteer.ordered_voice_numbers.first)
    end

    it "should increment voice retries if the number called is the last voice number of the volunteer" do
      lambda do
        @placer.place_call @candidate, @channel
      end.should change(@candidate, :voice_retries).by(1)
    end

    context "with Verboice exception" do
      before(:each) do
        @verboice.expects(:call).raises(Verboice::Exception)
      end

      it "should set last voice attempt, call status and increment retries" do
        Timecop.freeze
        number = @candidate.next_number_to_call
        retries = @candidate.voice_retries

        @placer.place_call @candidate, @channel

        @candidate.last_voice_att.should eq(Time.now)
        @candidate.last_voice_number.should eq(number)
        @candidate.voice_retries.should eq(retries + 1)
        @candidate.last_call_status.should eq('failed')
      end

      it "should not create a current call" do
        lambda do 
          @placer.place_call @candidate, @channel
        end.should_not change(CurrentCall, :count)
      end
    end
  end

  describe "next_deadline" do
    before(:each) do
      Timecop.freeze

      @mission = make_mission
      @candidate = Candidate.make! mission: @mission, last_voice_att: 1.minute.ago
      @scheduler.stubs(:has_voice_channels?).returns(true)
      @placer.next_deadline.should_not be_nil
    end

    it "should return nil if there are no voice channels" do
      @scheduler.expects(:has_voice_channels?).returns(false)
      @placer.next_deadline.should be_nil
    end

    it "should only consider pending and active candidates" do
      @candidate.update_attribute :active, false
      @placer.next_deadline.should be_nil

      @candidate.update_attributes active: true, status: :denied
      @placer.next_deadline.should be_nil
    end

    it "should only consider candidates with voice retries" do
      @candidate.update_attribute :voice_retries, @organization.max_voice_retries
      @placer.next_deadline.should be_nil
    end

    it "should only consider running missions" do
      @mission.update_attribute :status, :paused
      @placer.next_deadline.should be_nil
    end

    it "should add voice timeout only if it called the last voice number" do
      @placer.next_deadline.should eq(1.minute.ago) 
      @candidate.update_attribute :last_voice_number, @candidate.volunteer.ordered_voice_numbers.last
      @placer.next_deadline.should eq(1.minute.ago + @organization.voice_timeout.minutes)
    end

    it "should consider only running missions for the current organization" do
      @other_org = Organization.make!
      @other_mission = Mission.make! organization: @other_org, status: :running
      @other_candidate = Candidate.make! status: :pending, mission: @other_mission

      @mission.update_attribute :status, :paused
      @placer.next_deadline.should be_nil
    end
  end
end

