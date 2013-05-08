require 'spec_helper' 

describe "mission" do 
 
  it "should recruit nearest volunteers", js:true do
    user = User.make!
    organization = user.create_organization Organization.make
    volunteer = Volunteer.make! :organization => organization, :lat => -34.603333, :lng => -58.381667, :address => "Buenos Aires"
    3.times do    
    Volunteer.make! :organization => organization, :lat => -34.603333, :lng => -58.381667, :address => "Buenos Aires"
    end
    volunteer2 = Volunteer.make! :organization => organization, :lat => -33.8, :lng => -59.516667, :address => "Baradero"
    3.times do    
    Volunteer.make! :organization => organization, :lat => -33.8, :lng => -59.516667, :address => "Baradero"
    end
    login_as (user)
    visit missions_path
    click_link 'Create Event'
    fill_in 'name', :with => "Earthquake in Zarate"
    fill_in 'reason', :with => "Zarate village evacuation"
    fill_in 'address', :with => "-34.083333, -59.033333\n"
    sleep 10
    click_button 'Start recruiting'
    page.should have_content  "#{volunteer2.name}"
    page.should_not have_content  "#{volunteer.name}"
    page.save_screenshot 'Recruit_nearest_volunteers.png'
  end
  
end
