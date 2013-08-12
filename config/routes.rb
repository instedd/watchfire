Watchfire::Application.routes.draw do
  devise_for :users, :controllers => { :registrations => "users/registrations", :invitations => "users/invitations", omniauth_callbacks: "omniauth_callbacks" }

  # Verboice callbacks
  post "verboice/plan" => "verboice#plan", :defaults => { :format => 'xml' }
  post "verboice/callback" => "verboice#callback", :defaults => { :format => 'xml' }
  post "verboice/after_confirmation" => "verboice#plan_after_confirmation", :defaults => { :format => 'xml' }
  get "verboice/status_callback" => "verboice#status_callback"

  # Nuntium Callbacks
  post "nuntium/receive"

  # Pigeon mount
  authenticate :user do
    mount Pigeon::Engine => '/pigeon'
  end

  resources :organizations do
    member do
      get 'select'
    end
  end

  resources :missions do
    member do
      post 'start'
      post 'stop'
      post 'finish'
      post 'open'
			get 'export'
			post 'check_all'
			post 'uncheck_all'
    end
  end

  resources :volunteers do
    collection do
      post 'import'
      post 'confirm_import'
    end
  end

  resources :members do
    collection do
      post 'invite'
      get 'accept_invite'
    end
  end

  resources :channels, except: [:show] do
  end

	resources :candidates, :only => [:update]

  root :to => "missions#index"
end
