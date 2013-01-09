Watchfire::Application.routes.draw do
  devise_for :users, :controllers => { :registrations => "users/registrations", :invitations => "users/invitations" }

  # Verboice callbacks
  post "verboice/plan" => "verboice#plan", :defaults => { :format => 'xml' }
  post "verboice/callback" => "verboice#callback", :defaults => { :format => 'xml' }
  get "verboice/status_callback" => "verboice#status_callback"

  # Nuntium Callbacks
  post "nuntium/receive"

  resources :organizations do
    member do
      get 'select'
      post 'invite_user'
    end
  end

  resources :missions do
    member do
      post 'start'
      post 'stop'
      post 'finish'
      post 'open'
      get 'refresh'
      post 'clone'
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

	resources :candidates, :only => [:update]

  root :to => "missions#index"
end
