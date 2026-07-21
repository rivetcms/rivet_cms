RivetCms::Engine.routes.draw do
  root to: "dashboard#show"

  resources :content_types do
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

  resources :components do
    collection do
      post :create_category
    end
  end
end
