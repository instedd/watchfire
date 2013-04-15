class Verboice
  
  def self.from_config
    config = Watchfire::Application.config
    Verboice.new config.verboice_host, config.verboice_account, config.verboice_password
  end
  
end
