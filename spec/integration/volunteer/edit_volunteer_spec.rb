require 'spec_helper' 

describe "volunteer" do 
 
  it "should edit volunteer", js:true do
    user = User.make!
    organization = user.create_organization Organization.make
    volunteer = Volunteer.make! :organization => organization
    login_as (user)
    visit volunteers_path
    find(:xpath, '//tr[@class="link"]/td[1]').click
    click_button 'remove'
    fill_in 'new_voice_number', :with => '802346593' 
    fill_in 'new_sms_number', :with => '802346593'
    click_button 'Save'
    page.should have_content  "#{volunteer.name} was successfully updated."
    page.should have_content '802346593'
    page.save_screenshot 'Edit_volunteer.png'
  end
  
end
