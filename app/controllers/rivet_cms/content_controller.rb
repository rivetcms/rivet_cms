module RivetCms
  class ContentController < ApplicationController
    # The read API is token-gated (or public when RivetCms.public_api), so host
    # admin auth/CSRF must not run, and the org comes from the token, not the host.
    skip_before_action :authenticate_rivet_user
    skip_before_action :set_rivet_current_user
    skip_before_action :set_current_organization
    skip_after_action :set_csrf_cookie

    before_action :resolve_api_access

    DEFAULT_PER_PAGE = 25
    MAX_PER_PAGE = 100
    DOCUMENT_SORTS = { "created_at" => :created_at, "updated_at" => :updated_at, "slug" => :slug }.freeze

    def index
      populate = requested_populate

      base = content_type.documents.where.not(published_revision_id: nil).includes(:published_revision)
      scope = ordered(filtered(base))
      page = scope.page(params[:page]).per(per_page)

      revisions = page.map(&:published_revision)
      preload = RevisionPreloader.new(revisions, populate_fields: populate)

      render json: {
        data: revisions.map { |revision|
          RevisionSerializer.new(revision, fields: selected_field_keys, populate: populate, preload: preload).as_json
        },
        meta: { page: page.current_page, per_page: page.limit_value, total: page.total_count, total_pages: page.total_pages }
      }
    end

    def show
      return head :forbidden if preview_requested? && !preview_scope?

      populate = requested_populate

      document = content_type.documents.find_by!(slug: params[:slug])
      preview = preview_requested?
      revision = preview ? (document.draft_revision || document.published_revision) : document.published_revision
      return head :not_found if revision.nil?

      preload = RevisionPreloader.new([ revision ], populate_fields: populate, preview: preview)
      render json: RevisionSerializer.new(revision, fields: selected_field_keys, populate: populate, preview: preview, preload: preload).as_json
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

    def per_page
      requested = params[:per_page].to_i
      requested = DEFAULT_PER_PAGE if requested <= 0
      requested.clamp(1, MAX_PER_PAGE)
    end

    def reference_fields
      @reference_fields ||= content_type.fields.kept.reference.ordered.to_a
    end

    # Validates both params, then drops populated fields that a fields
    # selection excludes so their targets are never needlessly preloaded.
    def requested_populate
      populate = populate_fields
      keys = selected_field_keys
      keys ? populate.select { |field| keys.include?(field.key) } : populate
    end

    def populate_fields
      raw = params[:populate].to_s
      return [] if raw.blank?
      return reference_fields if raw.strip == "*"

      raw.split(",").map(&:strip).reject(&:blank?).map do |key|
        reference_fields.find { |field| field.key == key } ||
          raise(ApiQueryError, "cannot populate field: #{key}")
      end
    end

    def selected_field_keys
      return @selected_field_keys if defined?(@selected_field_keys)

      keys = params[:fields].to_s.split(",").map(&:strip).reject(&:blank?)
      return @selected_field_keys = nil if keys.empty?

      unknown = keys - content_type.fields.kept.pluck(:key)
      raise ApiQueryError, "unknown field: #{unknown.first}" if unknown.any?

      @selected_field_keys = keys
    end

    def ordered(scope)
      key, direction = parse_sort
      return scope.order(DOCUMENT_SORTS.fetch(key) => direction) if DOCUMENT_SORTS.key?(key)

      if key == "published_at"
        return scope
          .joins("INNER JOIN rivet_cms_document_revisions pub ON pub.id = rivet_cms_documents.published_revision_id")
          .order(Arel.sql("pub.published_at #{direction}"))
      end

      field = date_field(key)
      raise ApiQueryError, "unknown sort field: #{key}" if field.nil?

      scope.joins(field_join(field, "cv_sort")).order(Arel.sql("cv_sort.#{date_column(field)} #{direction}"))
    end

    def filtered(scope)
      date_range_params.each_with_index do |(key, bounds), index|
        field = date_field(key)
        raise ApiQueryError, "unknown filter field: #{key}" if field.nil?

        alias_name = "cv_f#{index}"
        scope = scope.joins(field_join(field, alias_name))
        scope = apply_bound(scope, field, alias_name, ">=", bounds["gte"]) if bounds["gte"].present?
        scope = apply_bound(scope, field, alias_name, "<=", bounds["lte"]) if bounds["lte"].present?
      end
      scope
    end

    def parse_sort
      raw = params[:sort].to_s
      return [ "published_at", :desc ] if raw.blank?

      raw.start_with?("-") ? [ raw[1..], :desc ] : [ raw, :asc ]
    end

    def field_join(field, alias_name)
      <<~SQL.squish
        LEFT JOIN rivet_cms_content_values #{alias_name}
          ON #{alias_name}.owner_type = 'RivetCms::DocumentRevision'
         AND #{alias_name}.owner_id = rivet_cms_documents.published_revision_id
         AND #{alias_name}.field_id = #{field.id.to_i}
      SQL
    end

    def apply_bound(scope, field, alias_name, operator, value)
      scope.where("#{alias_name}.#{date_column(field)} #{operator} ?", parse_date(field, value))
    end

    def date_field(key)
      content_type.fields.kept.find_by(key: key, field_type: [ :date, :datetime ])
    end

    def date_column(field)
      field.date? ? "date_value" : "datetime_value"
    end

    def parse_date(field, value)
      parsed = field.date? ? Date.parse(value) : Time.zone.parse(value)
      raise ApiQueryError, "invalid date: #{value}" if parsed.nil?

      parsed
    rescue ArgumentError, TypeError, Date::Error
      raise ApiQueryError, "invalid date: #{value}"
    end

    def date_range_params
      params.to_unsafe_h.select { |_key, value| value.is_a?(Hash) && (value.key?("gte") || value.key?("lte")) }
    end

    class ApiQueryError < StandardError; end

    rescue_from ApiQueryError do |error|
      render json: { error: error.message }, status: :bad_request
    end

    rescue_from ActiveRecord::RecordNotFound do
      render json: { error: "Not found" }, status: :not_found
    end
  end
end
