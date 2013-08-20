require 'spec_helper'

describe VolunteerImporter do
  TestLocation = Struct.new(:lat, :lng)
  before(:each) do
    @organization = Organization.make
    @importer = VolunteerImporter.new(@organization)
    Geokit::Geocoders::GoogleGeocoder3.stubs(:geocode).returns(TestLocation.new(123, 456))
  end

  describe "parse header" do
    it "finds name" do
      columns = @importer.parse_header ["Name"]
      columns.should eq({name: 0})

      columns = @importer.parse_header ["# Name"]
      columns.should eq({name: 0})
    end

    it "finds address" do
      columns = @importer.parse_header ["Address"]
      columns.should eq({address: 0})
    end

    it "finds lat and lng" do
      columns = @importer.parse_header ["Lat", "Lng"]
      columns.should eq({lat: 0, lng: 1})
    end

    it "finds voice phone numbers" do
      columns = @importer.parse_header ["Voice Number"]
      columns.should eq({voice: [0]})

      columns = @importer.parse_header ["Phone 1", "Phone 2"]
      columns.should eq({voice: [0, 1]})
    end

    it "finds sms phone numbers" do
      columns = @importer.parse_header ["SMS Number"]
      columns.should eq({sms: [0]})

      columns = @importer.parse_header ["SMS Phone"]
      columns.should eq({sms: [0]})
    end

    it "finds skills" do
      columns = @importer.parse_header ["Skills"]
      columns.should eq({skills: 0})

      columns = @importer.parse_header ["Roles"]
      columns.should eq({skills: 0})
    end

    it "finds shifts" do
      columns = @importer.parse_header ["avail_sunday_0000", "avail_monday_0300"]
      columns.should eq({shifts: {['sunday', 0] => 0, ['monday', 3] => 1}})
    end
  end

  describe "parse row" do
    it "sets organization" do
      row = @importer.parse_row [], {}
      row.organization.should eq(@organization)
    end

    it "sets name" do
      row = @importer.parse_row ["John"], {name: 0}
      row.name.should eq("John")
    end

    it "sets address" do
      row = @importer.parse_row ["Somewhere"], {address: 0}
      row.address.should eq("Somewhere")
    end

    it "sets phones" do
      row = @importer.parse_row ["123", "456", "789"], {voice: [0, 1], sms: [2]}
      row.voice_channels.map(&:address).should eq(["123", "456"])
      row.sms_channels.map(&:address).should eq(["789"])
    end

    it "sets skills" do
      row = @importer.parse_row ["foo / bar | baz"], {skills: 0}
      row.skills.map(&:name).should eq(["foo", "bar", "baz"])
    end

    it "sets location from address when not lat/lng are provided" do
      row = @importer.parse_row ["Somewhere"], {address: 0}
      row.lat.should eq(123)
      row.lng.should eq(456)
    end

    it "sets location from address when lat/lng are provided but incorrect" do
      row = @importer.parse_row ["Somewhere", "foo", "bar"], {address: 0, lat: 1, lng: 2}
      row.address.should eq("Somewhere")
      row.lat.should eq(123)
      row.lng.should eq(456)
    end

    it "sets provided lat/lng" do
      row = @importer.parse_row ["Somewhere", "33.3", "44.4"], {address: 0, lat: 1, lng: 2}
      row.address.should eq("Somewhere")
      row.lat.should eq(33.3)
      row.lng.should eq(44.4)
    end

    it "sets shifts" do
      shifts = {
        ['sunday', 0] => 0,
        ['sunday', 1] => 1,
        ['monday', 2] => 2,
        ['monday', 3] => 3,
        ['tuesday', 4] => 4,
        ['tuesday', 5] => 5
      }
      row = @importer.parse_row ["true", "1", "false", "0", "", nil], {shifts: shifts}
      row.shifts.length.should eq(7)
      row.shifts.values.all?{|d| d.length == 24}.should be_true
      row.available?(:sunday, 0).should be_true
      row.available?(:sunday, 1).should be_true
      row.available?(:monday, 2).should be_false
      row.available?(:monday, 3).should be_false
      row.available?(:tuesday, 4).should be_false
      row.available?(:tuesday, 5).should be_false
    end
  end

  describe "parse entire files" do
    it "imports main format" do
      csv = File.read(File.join(Rails.root, "public/samples/volunteers.csv"))
      volunteers = @importer.import(csv)
      volunteers.length.should eq(5)

      volunteers[0].name.should eq("Boris Stein")
      volunteers[0].skills.map(&:name).should eq(["Team Lead"])
      volunteers[0].voice_channels.map(&:address).should eq(["15651464662"])
      volunteers[0].sms_channels.map(&:address).should eq(["12841625543"])
      volunteers[0].lat.should eq(123)
      volunteers[0].lng.should eq(456)

      volunteers[1].name.should eq("Bertha Rodgers")
      volunteers[1].skills.map(&:name).should eq([])
      volunteers[1].voice_channels.map(&:address).should eq(["18916001651"])
      volunteers[1].sms_channels.map(&:address).should eq(["11267888639"])
      volunteers[1].lat.should eq(123)
      volunteers[1].lng.should eq(456)

      volunteers[4].name.should eq("Ramona Harper")
      volunteers[4].skills.map(&:name).should eq(["Trainee", "FSI Lead"])
      volunteers[4].voice_channels.map(&:address).should eq(["13482760403"])
      volunteers[4].sms_channels.map(&:address).should eq(["11462818260"])
      volunteers[4].lat.should eq(123)
      volunteers[4].lng.should eq(456)
    end

    it "imports big format" do
      csv = File.read(File.expand_path("../test2.csv", __FILE__))
      volunteers = @importer.import(csv)
      volunteers.length.should eq(1)
      volunteers[0].name.should eq("Annabella Abea")
      volunteers[0].address.should eq("19105 ROSARIO CT  HAYWARD, CA, 94541-1731")
      volunteers[0].lat.should eq(32.1)
      volunteers[0].lng.should eq(45.6)
      volunteers[0].voice_channels.map(&:address).should eq(["5107068391"])
      volunteers[0].sms_channels.map(&:address).should eq(["837237232"])
      volunteers[0].skills.map(&:name).should eq(["dat"])
      volunteers[0].available?(:sunday, 0).should be_true
      volunteers[0].available?(:sunday, 1).should be_false
    end
  end
end
