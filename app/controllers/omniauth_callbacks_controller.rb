class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def method_missing(name, *args)
    auth = env['omniauth.auth']

    if identity = Identity.find_by_provider_and_token(auth['provider'], auth['uid'])
      user = identity.user
    else
      user = User.find_by_email(auth.info['email'])
      unless user
        password = Devise.friendly_token
        user = User.new
        user.email = auth.info['email']
        user.confirmed_at = Time.now
        user.password = password
        user.password_confirmation = password
        user.save!
        user
      end
      user.identities.create! provider: auth['provider'], token: auth['uid']
    end

    sign_in user
    next_url = env['omniauth.origin'] || root_path
    next_url = root_path if next_url == new_user_session_url
    redirect_to next_url
  end
end
