module RivetCms
  class DashboardController < ApplicationController
    def index
      @content_types = ContentType.order(:name)
      @recent_contents = Content.order(updated_at: :desc).limit(5)
      @components = Component.all
      @content_type = ContentType.new
    end
  end
end
