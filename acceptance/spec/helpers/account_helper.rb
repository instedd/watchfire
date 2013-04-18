module AccountHelper
  def login_as(login, password)
    @driver.find_element(:id, "user_email").clear
    @driver.find_element(:id, "user_email").send_keys login
    @driver.find_element(:id, "user_password").clear
    @driver.find_element(:id, "user_password").send_keys password
    @driver.find_element(:xpath, "//div[contains(@class, 'actions')]/button").click
  end

  def logout
    @driver.find_element(:xpath, "//div[contains(@id, 'User')]").click
    sleep 5
    @driver.find_element(:link, "Log Out").click
    #@driver.find_element(:xpath, "//div[contains(@class, 'container')]/a").click
    sleep 10
  end
end
