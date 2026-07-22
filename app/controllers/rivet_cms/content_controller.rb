module RivetCms
  class ContentController < ApplicationController
    def index
      documents = content_type.documents.where.not(published_revision_id: nil)
      render json: documents.map { |document| RevisionSerializer.new(document.published_revision).as_json }
    end

    def show
      document = content_type.documents.find_by!(slug: params[:slug])
      revision = document.published_revision
      return head :not_found if revision.nil?

      render json: RevisionSerializer.new(revision).as_json
    end

    private

    def content_type
      @content_type ||= Current.organization.content_types.find_by!(slug: params[:content_type_slug])
    end
  end
end
