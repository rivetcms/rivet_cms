module RivetCms
  module Api
    class DocsController < RivetCms::ApplicationController
      layout false
      
      def show
        @schema = RivetCms::OpenApiGenerator.generate
        
        respond_to do |format|
          format.html
          format.json { render json: @schema }
          format.yaml { render plain: @schema.to_yaml, content_type: 'application/x-yaml' }
        rescue StandardError => e
          Rails.logger.error "Error generating API documentation: #{e.message}"
          render_error_response(format)
        end
      end

      private

      def render_error_response(format)
        error_schema = {
          openapi: "3.0.1",
          info: {
            title: "API Documentation Temporarily Unavailable",
            version: "1.0.0",
            description: "There was an error generating the API documentation. Please try again later."
          },
          paths: {}
        }

        format.html { render :error, status: :internal_server_error }
        format.json { render json: error_schema, status: :internal_server_error }
        format.yaml { render plain: error_schema.to_yaml, status: :internal_server_error }
      end
    end
  end
end 