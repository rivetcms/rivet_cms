module RivetCms
  # One place to find everything trashed, so recovering does not depend on
  # remembering which content type something belonged to. Entries of removed
  # types are represented by their type below: restoring the type brings its
  # entries back with it.
  class TrashController < ApplicationController
    include InertiaProps

    before_action -> { authorize! :read, :content }

    def show
      scope = trashed_entries
      if params[:type].present?
        scope = scope.joins(:content_type).where(rivet_cms_content_types: { slug: params[:type] })
      end
      scope = scope.search(params[:q]) if params[:q].present?
      page = scope.includes(:content_type, :draft_revision).order(deleted_at: :desc).page(params[:page]).per(25)
      entries = permitted_documents(page)
      titles = document_titles(entries)

      render inertia: "Trash/Show", props: {
        documents: entries.map { |document|
          document_list_props(document, titles).merge(
            content_type_name: document.content_type.name,
            trashed_at: document.deleted_at.iso8601,
            paths: {
              restore: restore_content_type_document_path(document.content_type, document),
              purge: purge_content_type_document_path(document.content_type, document)
            }
          )
        },
        q: params[:q].presence,
        type: params[:type].presence,
        # Filter options come from what is actually trashed, like media kinds
        types: filter_types,
        pagination: { page: page.current_page, total_pages: page.total_pages },
        content_types: removed_content_types
      }
    end

    private

    def trashed_entries
      Document.with_discarded.discarded.in_visible_types.where(organization: Current.organization)
    end

    def filter_types
      permitted(ContentType.where(id: trashed_entries.distinct.select(:content_type_id)).order(:name), :read, :content)
        .map { |content_type| { slug: content_type.slug, name: content_type.name } }
    end

    # Removed types are schema data; without schema read the section is empty
    def removed_content_types
      return [] unless can?(:read, :schema)

      removed = permitted(ContentType.with_discarded.discarded.where(organization: Current.organization).order(:deleted_at), :read, :schema)
      entry_counts = Document.with_discarded.where(content_type_id: removed.map(&:id)).group(:content_type_id).count

      removed.map { |content_type|
        content_type_props(content_type).merge(
          removed_at: content_type.deleted_at.iso8601,
          documents_count: entry_counts.fetch(content_type.id, 0),
          paths: { restore: restore_content_type_path(content_type), purge: purge_content_type_path(content_type) }
        )
      }
    end
  end
end
