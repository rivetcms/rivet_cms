RivetCms::Engine.routes.draw do
  get "components/index"
  get "components/new"
  get "components/edit"
  root to: "dashboard#show"

  resources :content_types do
    resources :fields, except: [ :show ] do
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

  resources :components do
    collection do
      post :create_category
    end
    resources :fields, except: [ :show ] do
      collection do
        post :update_layout
      end
    end
  end
end
