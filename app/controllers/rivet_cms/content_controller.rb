module RivetCms
  class ContentController < ApplicationController
    # The read API serves published content publicly; host auth must not run
    # (a host current_user lambda may assume a signed-in session).
    skip_before_action :authenticate_rivet_user
    skip_before_action :set_rivet_current_user
    skip_after_action :set_csrf_cookie

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
