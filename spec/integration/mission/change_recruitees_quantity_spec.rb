require 'spec_helper' 

describe "mission" do 
 
  it "should change recruitees quantity", js:true do
    user = User.make!
    organization = user.create_organization Organization.make
    volunteer = Volunteer.make! :organization => organization, :lat => 15, :lng => 19, :address => "Chad"
    mission = Mission.make! :user => user, :organization => organization, :status => :running, :lat => 15, :lng => 19
    6.times do    
    Volunteer.make! :organization => organization, :lat => 15, :lng => 19, :address => "Chad"
    end
    volunteer2 = Volunteer.make! :organization => organization, :lat => 15, :lng => 19, :address => "Chad"
    Candidate.make! :status => 'pending', :mission => mission, :volunteer => volunteer
    login_as (user)
    visit missions_path
    find(:xpath, '//tr[@class="mission link"]/td[1]').click
    click_button 'Pause'
    sleep 5
    find(:xpath, '//div[@id="form_container"]/div[2]/div/span[1]/button[2]').click
    sleep 5
    click_button 'Resume'
    page.should have_content  "#{volunteer2.name}"
    page.save_screenshot 'Change_recruitees_quantity.png'
  end
  
end
