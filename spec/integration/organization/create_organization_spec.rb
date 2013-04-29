require 'spec_helper' 

describe "organization" do 
 
  it "should create organization", js:true do
    user = User.make!
    login_as (user)
    visit missions_path
    click_link 'Create Organization'
    fill_in 'organization_name', :with => 'First Organization'
    click_button 'Create Organization'
    sleep 3
    page.should have_content 'Organization was successfully created'
    page.should have_content "First Organization"
    page.save_screenshot 'Create_organization.png'
  end
  
end
