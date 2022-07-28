Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  scope :api do
    scope :badgr do
      get '/token', to: 'badgr#get_token'
      get '/badges', to: 'badgr#get_badges'
      post '/badge', to: 'badgr#issue_badge'
      get '/assertions', to: 'badgr#get_issued_badges'
      get '/backpack', to: 'badgr#get_backpack'
    end
  end
end
