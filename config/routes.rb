Watchfire::Application.routes.draw do
  devise_for :users, :controllers => { :registrations => "users/registrations", :invitations => "users/invitations" }

  # Verboice callbacks
  post "verboice/plan" => "verboice#plan", :defaults => { :format => 'xml' }
  post "verboice/callback" => "verboice#callback", :defaults => { :format => 'xml' }

  # Nuntium Callbacks
  post "nuntium/receive"

  resources :missions do
    member do
      post 'start'
      post 'stop'
      post 'finish'
      post 'open'
      get 'refresh'
      post 'clone'
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
