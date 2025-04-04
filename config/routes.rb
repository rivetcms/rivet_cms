RivetCms::Engine.routes.draw do
  RivetCms::Routes.add_routes do
    get '/', to: "dashboard#index", as: :dashboard

    # Content Type Management
    resources :content_types, path: 'content-types' do
      resources :fields, except: [:show] do
        collection do
          post :update_positions
        end
        member do
          patch :update_width
        end
      end
      resources :contents
    end

    # Component Management
    resources :components do
      resources :fields, except: [:show] do
        collection do
          post :update_positions
        end
      end
    end

    # API Documentation
    namespace :api do
      resource :docs, only: [:show]
    end

    # Helper method to check if content type exists and matches the collection/single type
    content_type_exists = ->(slug, is_collection) {
      RivetCMS::ContentType.exists?(slug: slug, is_single: !is_collection)
    }

    # API routes with versioning
    namespace :api do
      namespace :v1 do
        # Dynamic routes for content types
        get ':slug', to: 'content#index', constraints: ->(req) { content_type_exists.call(req.params[:slug], true) }
        post ':slug', to: 'content#create', constraints: ->(req) { content_type_exists.call(req.params[:slug], true) }
        get ':slug/:id', to: 'content#show', constraints: ->(req) { content_type_exists.call(req.params[:slug], true) }
        put ':slug/:id', to: 'content#update', constraints: ->(req) { content_type_exists.call(req.params[:slug], true) }
        patch ':slug/:id', to: 'content#update', constraints: ->(req) { content_type_exists.call(req.params[:slug], true) }
        delete ':slug/:id', to: 'content#destroy', constraints: ->(req) { content_type_exists.call(req.params[:slug], true) }

        # Routes for single type content
        get ':slug', to: 'single#show', constraints: ->(req) { content_type_exists.call(req.params[:slug], false) }
        put ':slug', to: 'single#update', constraints: ->(req) { content_type_exists.call(req.params[:slug], false) }
        patch ':slug', to: 'single#update', constraints: ->(req) { content_type_exists.call(req.params[:slug], false) }
        post ':slug', to: 'single#update', constraints: ->(req) { content_type_exists.call(req.params[:slug], false) }
      end
    end
  end

  RivetCms::Routes.draw_routes
end
