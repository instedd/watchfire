Pigeon.setup do |config|
  watchfire_config = YAML::load_file("#{Rails.root}/config/settings.yml")[Rails.env]

  config.application_name = 'Watchfire'

  config.nuntium_host = watchfire_config['nuntium_host']
  config.nuntium_account = watchfire_config['nuntium_account']
  config.nuntium_app = watchfire_config['nuntium_app']
  config.nuntium_app_password = watchfire_config['nuntium_app_passwd']

  config.verboice_host = watchfire_config['verboice_host']
  config.verboice_account = watchfire_config['verboice_account']
  config.verboice_password = watchfire_config['verboice_password']
  config.verboice_default_call_flow = watchfire_config['verboice_default_call_flow']

  config.twitter_consumer_key = watchfire_config['twitter_consumer_key']
  config.twitter_consumer_secret = watchfire_config['twitter_consumer_secret']
end
