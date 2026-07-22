module RivetCms
  class ContentController < ApplicationController
    # The read API is token-gated (or public when RivetCms.public_api), so host
    # admin auth/CSRF must not run, and the org comes from the token, not the host.
    skip_before_action :authenticate_rivet_user
    skip_before_action :set_rivet_current_user
    skip_before_action :set_current_organization
    skip_after_action :set_csrf_cookie

    before_action :resolve_api_access

    def index
      populate = query.populate_fields

      page = query.documents
      revisions = page.map(&:published_revision)
      preload = RevisionPreloader.new(revisions, populate_fields: populate)

      render json: {
        data: revisions.map { |revision|
          RevisionSerializer.new(revision, fields: query.field_keys, populate: populate, preload: preload).as_json
        },
        meta: { page: page.current_page, per_page: page.limit_value, total: page.total_count, total_pages: page.total_pages }
      }
    end

    def show
      return head :forbidden if preview_requested? && !preview_scope?

      populate = query.populate_fields

      document = content_type.documents.find_by!(slug: params[:slug])
      preview = preview_requested?
      revision = preview ? (document.draft_revision || document.published_revision) : document.published_revision
      return head :not_found if revision.nil?

      preload = RevisionPreloader.new([ revision ], populate_fields: populate, preview: preview)
      render json: RevisionSerializer.new(revision, fields: query.field_keys, populate: populate, preview: preview, preload: preload).as_json
    end

    private

    def resolve_api_access
      raw = bearer_token
      if raw.present?
        token = ApiToken.authenticate(raw)
        return render_unauthorized if token.nil?

        RivetCms::Current.organization = token.organization
        @api_scope = token.scope.to_sym
        token.touch_used!
      elsif RivetCms.public_api
        set_current_organization
        @api_scope = :published
      else
        render_unauthorized
      end
    end

    def bearer_token
      request.authorization.to_s[/\ABearer (.+)\z/i, 1]
    end

    def render_unauthorized
      response.set_header("WWW-Authenticate", 'Bearer realm="RivetCms delivery API"')
      render json: { error: "Invalid or missing API token" }, status: :unauthorized
    end

    def preview_requested?
      ActiveModel::Type::Boolean.new.cast(params[:preview])
    end

    def preview_scope?
      @api_scope == :preview
    end

    def content_type
      @content_type ||= Current.organization.content_types.find_by!(slug: params[:content_type_slug])
    end

    def query
      @query ||= ContentQuery.new(
        content_type,
        sort: params[:sort],
        filters: date_range_params,
        page: params[:page],
        per_page: params[:per_page],
        populate: params[:populate].to_s,
        fields: params[:fields].to_s
      )
    end

    def date_range_params
      params.to_unsafe_h.select { |_key, value| value.is_a?(Hash) && (value.key?("gte") || value.key?("lte")) }
    end

    rescue_from ContentQuery::Error do |error|
      render json: { error: error.message }, status: :bad_request
    end

    rescue_from ActiveRecord::RecordNotFound do
      render json: { error: "Not found" }, status: :not_found
    end
  end
end
