module RivetCms
  class ContentTypesController < ApplicationController
    include InertiaProps

    before_action -> { authorize! :read, :schema }, only: [ :index, :show, :trash ]
    # Restore mirrors removal, gates included: un-removing a type puts its
    # entries back on the delivery API, so it is no smaller an action.
    before_action -> { authorize! :delete, :schema }, only: [ :destroy, :purge, :restore ]
    before_action -> { authorize! :write, :schema }, except: [ :index, :show, :trash, :destroy, :purge, :restore ]
    before_action :set_content_type, only: [ :show, :update, :destroy ]
    before_action :set_removed_content_type, only: [ :restore, :purge ]
    # Purging destroys content, so it needs the content gate as well as schema
    before_action -> { authorize! :delete, :content }, only: [ :purge ]
    before_action :authorize_cascade!, only: [ :destroy, :restore ]
    # Record layer: same gates, about this specific type
    before_action -> { authorize! :read, :schema, record: @content_type }, only: [ :show ]
    before_action -> { authorize! :write, :schema, record: @content_type }, only: [ :update ]
    before_action -> { authorize! :delete, :schema, record: @content_type }, only: [ :destroy, :restore, :purge ]
    before_action -> { authorize! :delete, :content, record: @content_type }, only: [ :purge ]

    def index
      # Entry counts are content data, not schema; omit them without content read
      entry_counts = can?(:read, :content) ? Document.where(organization: Current.organization).in_visible_types.group(:content_type_id).count : nil

      render inertia: "ContentTypes/Index", props: {
        removed_count: ContentType.with_discarded.discarded.where(organization: Current.organization).count,
        content_types: permitted(Current.organization.content_types, :read, :schema).map { |ct|
          props = content_type_props(ct)
          entry_counts ? props.merge(documents_count: entry_counts.fetch(ct.id, 0)) : props
        }
      }
    end

    def show
      fields = @content_type.fields.kept.ordered

      render inertia: "ContentTypes/Show", props: {
        content_type: content_type_props(@content_type),
        fields: fields.map { |f| field_props(f) },
        field_types: Field::FIELD_TYPE_LABELS,
        # Selectable targets for "reference" and "component" field options
        reference_targets: permitted(Current.organization.content_types.where.not(id: @content_type.id).order(:name), :read, :schema).map { |ct| { id: ct.id, name: ct.name } },
        embeddable_components: permitted(Current.organization.components.order(:name), :read, :schema).map { |c| { id: c.id, name: c.name } }
      }
    end

    def new
      render inertia: "ContentTypes/New"
    end

    def create
      content_type = ContentType.new(content_type_params)

      if content_type.save
        audit "content_type.created", content_type
        redirect_to content_type_path(content_type), notice: "Content type created successfully"
      else
        redirect_to new_content_type_path, inertia: { errors: content_type.errors }
      end
    end

    def update
      if @content_type.update(content_type_params)
        audit "content_type.updated", @content_type
        redirect_to content_type_path(@content_type), notice: "Content type updated successfully"
      else
        redirect_to content_type_path(@content_type), inertia: { errors: @content_type.errors }
      end
    end

    # Removed types are kept, so they need somewhere to be seen and restored
    def trash
      removed = permitted(ContentType.with_discarded.discarded.where(organization: Current.organization).order(:deleted_at), :read, :schema)
      entry_counts = can?(:read, :content) ? Document.with_discarded.where(content_type_id: removed.map(&:id)).group(:content_type_id).count : nil

      render inertia: "ContentTypes/Trash", props: {
        content_types: removed.map { |content_type|
          props = content_type_props(content_type).merge(
            removed_at: content_type.deleted_at.iso8601,
            paths: { restore: restore_content_type_path(content_type), purge: purge_content_type_path(content_type) }
          )
          entry_counts ? props.merge(documents_count: entry_counts.fetch(content_type.id, 0)) : props
        }
      }
    end

    def restore
      @content_type.undiscard!
      audit "content_type.restored", @content_type
      redirect_to content_type_path(@content_type), notice: "#{@content_type.name} was restored with its entries"
    end

    # The one place content is really destroyed. Only reachable from the trash,
    # and only when the typed name matches, so it cannot be a slip.
    def purge
      unless params[:confirm].to_s.strip == @content_type.name.to_s.strip
        return redirect_back fallback_location: trash_content_types_path, allow_other_host: false,
                             status: :see_other, alert: "Type the name exactly to permanently delete it"
      end

      name = @content_type.name
      ContentType.transaction do
        # with_discarded: trashed entries still hold the FK and must go too
        documents = Document.with_discarded.where(content_type_id: @content_type.id)
        # Incoming links hold a foreign key, so they go before their targets
        Relation.where(target_document_id: documents.select(:id)).delete_all
        documents.find_each(&:destroy!)
        @content_type.destroy!
      end

      audit "content_type.purged", @content_type
      # Back to whichever trash (global or scoped) the purge came from
      redirect_back fallback_location: trash_content_types_path, allow_other_host: false,
                    status: :see_other, notice: "#{name} and its entries were permanently deleted"
    rescue ActiveRecord::ActiveRecordError => error
      Rails.logger&.error("[RivetCms] purge failed for content type #{@content_type.id}: #{error.class}")
      redirect_back fallback_location: trash_content_types_path, allow_other_host: false,
                    status: :see_other, alert: "#{name} could not be deleted; nothing was removed"
    end

    def destroy
      @content_type.discard!
      audit "content_type.removed", @content_type
      redirect_to content_types_path,
                  notice: "#{@content_type.name} was removed. Its entries are kept and it can be restored from the trash."
    end

    private

    # Removing a type hides its entries from the admin and the delivery API,
    # so it is a content-level action as well as a schema one.
    def authorize_cascade!
      return unless Document.with_discarded.where(content_type_id: @content_type.id).exists?

      # Both phases, like every other gate: recordless first, then the record
      authorize! :delete, :content
      authorize! :delete, :content, record: @content_type
    end

    def set_removed_content_type
      @content_type = ContentType.with_discarded.discarded.where(organization: Current.organization).find(params[:id])
    end

    def set_content_type
      @content_type = Current.organization.content_types.find(params[:id])
    end

    def content_type_params
      params.require(:content_type).permit(:name, :slug, :description, :single)
    end
  end
end
