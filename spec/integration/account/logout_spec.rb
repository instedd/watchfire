require 'spec_helper' 

describe "account" do 
 
  it "should log out", js:true do
    user = User.make
    login_as (user)
    visit missions_path
    find_by_id('User').click
    click_link('Log Out')
    sleep 3
    page.save_screenshot 'Log_out.png'
    page.should have_content 'You need to sign in or sign up before continuing.'
  end
  
end
