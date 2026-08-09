RivetCms::Engine.routes.draw do
  root to: "dashboard#show"

  # Built-in authentication; these controllers 404 when the host wires its own
  get "login" => "sessions#new", as: :login
  post "login" => "sessions#create"
  delete "logout" => "sessions#destroy", as: :logout
  get "setup" => "setup#new", as: :setup
  post "setup" => "setup#create"
  get "join/:token" => "invitations#show", as: :invitation
  patch "join/:token" => "invitations#update"

  resources :users, only: [ :index, :create, :update ] do
    member do
      patch :deactivate
      patch :reactivate
      post :reset_link
    end
  end

  resources :content_types, except: [ :edit ] do
    collection do
      get :trash
    end
    member do
      patch :restore
      delete :purge
    end
    resources :fields, only: [ :create, :update, :destroy ] do
      member do
        patch :toggle_width
        patch :unpair
        patch :pair
      end
      collection do
        post :update_layout
      end
    end
  end

  resources :components, except: [ :edit ] do
    collection do
      post :create_category
    end
    resources :fields, only: [ :create, :update, :destroy ] do
      member do
        patch :toggle_width
        patch :unpair
        patch :pair
      end
      collection do
        post :update_layout
      end
    end
  end

  get "content", to: "content_manager#index", as: :content
  get "trash", to: "trash#show", as: :trash

  resources :media_assets, only: [ :index, :create, :update, :destroy ]
  resources :api_tokens, only: [ :index, :create, :destroy ]

  get "api-docs", to: "api_docs#show", as: :api_docs
  get "api-docs/openapi", to: "api_docs#spec", as: :api_openapi

  resources :content_types, only: [] do
    resources :documents, except: [ :show ] do
      collection do
        get :trash
      end
      member do
        post :publish
        patch :restore
        delete :purge
      end
    end
  end

  get "api/:content_type_slug", to: "content#index", as: :content_index
  get "api/:content_type_slug/:slug", to: "content#show", as: :content_show
end
