require 'spec_helper' 

describe "mission" do 
 
  it "should create mission", js:true do
    user = User.make!
    organization = user.create_organization Organization.make
    volunteer = Volunteer.make! :organization => organization, :lat => 15, :lng => 19, :address => "Chad"
    login_as (user)
    visit missions_path
    click_link 'Create Event'
    fill_in 'name', :with => "Earthquake in "
    fill_in 'reason', :with => "Chad village evacuation"
    fill_in 'address', :with => "15,19\n"
    click_button 'Start recruiting'
    page.should have_content  "#{volunteer.name}"
    page.save_screenshot 'Create_mission.png'
  end
  
end
