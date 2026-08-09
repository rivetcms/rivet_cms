Rails.application.routes.draw do
  get "/host/login", to: "sessions#new", as: :host_login
  post "/host/login", to: "sessions#create"
  delete "/host/logout", to: "sessions#destroy", as: :host_logout

  mount RivetCms::Engine => "/"
end
