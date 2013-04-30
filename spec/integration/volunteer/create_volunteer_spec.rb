require 'spec_helper' 

describe "volunteer" do 
 
  it "should create volunteer", js:true do
    user = User.make!
    organization = user.create_organization Organization.make
    login_as (user)
    visit missions_path
    click_link "Add New Volunteer"
    fill_in 'volunteer_name', :with => 'Nathan Arrington' 
    fill_in 'new_voice_number', :with => '802346593' 
    fill_in 'new_sms_number', :with => '802346593'
    fill_in 'volunteer_address', :with => "New york\n"
    click_button 'Save'
    sleep 30
    page.should have_content 'Nathan Arrington was successfully created.'
    page.should have_content 'Nathan Arrington'
    page.save_screenshot 'Create_volunteer.png'
  end
  
end
