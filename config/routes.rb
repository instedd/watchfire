Watchfire::Application.routes.draw do
  devise_for :users, :controllers => { :registrations => "users/registrations" }

  # Verboice callbacks
  post "verboice/plan" => "verboice#plan", :defaults => { :format => 'xml' }
  post "verboice/callback" => "verboice#callback", :defaults => { :format => 'xml' }

  # Nuntium Callbacks
  post "nuntium/receive"

  resources :missions do
    member do
      post 'start'
      post 'stop'
      get 'refresh'
    end
  end
  
  resources :volunteers
  
  root :to => "missions#index"
end
