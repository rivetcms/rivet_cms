module RivetCms
  class ApiDocsController < ApplicationController
    include InertiaProps

    before_action -> { authorize! :read, :api }
    # The docs render every type's fields, the same data /content_types gates
    before_action -> { authorize! :read, :schema }

    def show
      content_types = Current.organization.content_types.order(:name)

      render inertia: "Api/Index", props: {
        base_url: api_base_url,
        public_api: RivetCms.public_api,
        content_types: content_types.map { |ct| api_reference_props(ct) },
        doc_paths: { openapi: api_openapi_path, tokens: api_tokens_path }
      }
    end

    def spec
      generator = OpenApiGenerator.new(Current.organization, base_url: api_base_url)
      send_data JSON.pretty_generate(generator.as_json), type: :json, disposition: "attachment", filename: "openapi.json"
    end

    private

    def api_base_url
      "#{request.base_url}/api"
    end

    def api_reference_props(content_type)
      {
        name: content_type.name,
        slug: content_type.slug,
        single: content_type.single?,
        fields: content_type.fields.kept.ordered.map { |f| { key: f.key, type: f.field_type, required: f.required? } }
      }
    end
  end
end
