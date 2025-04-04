# Route handling pattern adapted from Spree Commerce
# https://github.com/spree/spree/blob/839866a32845009d8a1fdf21cb7201e99f6ff49c/core/lib/spree/core/routes.rb
# License: MIT - https://github.com/spree/spree/blob/main/LICENSE.md

module RivetCms
  module Routes
    def self.draw_routes(&block)
      @rivet_routes ||= []
      @append_routes ||= []

      # Evaluate an immediate block if given
      eval_block(block) if block_given?

      # Evaluate stored main routes
      @rivet_routes.each { |route_block| eval_block(&route_block) }

      # Evaluate appended routes
      @append_routes.each { |route_block| eval_block(&route_block) }

      # Clear routes to avoid duplication on subsequent calls
      @rivet_routes = []
      @append_routes = []
    end

    def self.add_routes(&block)
      @rivet_routes ||= []
      store_route(@rivet_routes, &block)
    end

    def self.append_routes(&block)
      @append_routes ||= []
      store_route(@append_routes, &block)
    end

    private

    # Helper method for safely storing a route block in the given collection.
    def self.store_route(collection, &block)
      collection << block unless collection.include?(block)
    end

    # Evaluate a block within the context of the engine's routes.
    def self.eval_block(&block)
      RivetCms::Engine.routes.draw do
        instance_exec(&block)
      end
    end
  end
end

