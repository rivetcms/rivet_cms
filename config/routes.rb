RivetCms::Engine.routes.draw do
  root to: "dashboard#show"

  resources :content_types, except: [ :edit ] do
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

  resources :media_assets, only: [ :index, :create, :destroy ]

  resources :content_types, only: [] do
    resources :documents do
      member do
        post :publish
      end
    end
  end

  get "api/:content_type_slug", to: "content#index", as: :content_index
  get "api/:content_type_slug/:slug", to: "content#show", as: :content_show
end
