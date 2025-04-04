module RivetCms
  class ComponentsController < ApplicationController
    def index
      @components = RivetCms::Component.all
    end
  end
end