module RivetCms
  class ContentManagerController < ApplicationController
    include InertiaProps

    def index
      render inertia: "ContentManager/Index", props: {
        content_types: Current.organization.content_types.map { |content_type| content_type_props(content_type) }
      }
    end
  end
end
