Watchfire::Application.routes.draw do
  # Verboice callbacks
  post "verboice/plan" => "verboice#plan", :defaults => { :format => 'xml' }
  post "verboice/callback" => "verboice#callback", :defaults => { :format => 'xml' }

  # Nuntium Callbacks
  post "nuntium/receive"

  resources :missions do
    member do
      post 'start'
      post 'stop'
    end
  end
  
  root :to => "missions#index"
end
