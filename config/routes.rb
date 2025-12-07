Rails.application.routes.draw do
  devise_for :users

  get "/upload", to: "home#upload"

  namespace :api do
    resources :simulations, only: [:create]
    post "simulations/:id/start", to: "simulations#start"
    post "simulations/:id/stop", to: "simulations#stop"
  end

  resources :simulations, only: [:show, :index]

  root to: redirect("/upload")
end