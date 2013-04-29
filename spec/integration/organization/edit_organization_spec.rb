require 'spec_helper' 

describe "organization" do 
 
  it "should edit organization", js:true do
    user = User.make!
    organization = user.create_organization Organization.make
    login_as (user)
    visit missions_path
    click_link organization.name 
    visit edit_organization_path(organization)
    fill_in 'organization_name', :with => 'Edited Organization Name'
    click_button 'Update Organization'
    sleep 3
    page.should have_content 'Organization was successfully updated'
    page.should_not have_content organization.name
    page.save_screenshot 'Edit_organization_name.png'
  end
  
end
