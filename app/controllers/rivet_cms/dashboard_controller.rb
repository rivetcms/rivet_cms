module RivetCms
  class DashboardController < ApplicationController
    include InertiaProps

    # The dashboard stays reachable by any authenticated user, but every
    # section's data is filtered through the same can? checks that gate the
    # section's own pages, so it never leaks what those pages would refuse.
    def show
      read_content = can?(:read, :content)
      read_schema = can?(:read, :schema)

      organization = Current.organization
      content_types = read_content || read_schema ? organization.content_types.order(:name).to_a : []
      documents = Document.where(organization: organization).in_visible_types
      entry_counts = read_content ? documents.group(:content_type_id).count : {}

      stats = {}
      stats[:entries] = documents.count if read_content
      if read_schema
        stats[:content_types] = content_types.size
        stats[:components] = organization.components.count
      end
      read_api = can?(:read, :api)
      stats[:media_assets] = organization.media_assets.count if can?(:read, :media)
      stats[:api_tokens] = organization.api_tokens.count if read_api

      render inertia: "Dashboard/Show", props: {
        stats: stats,
        has_fields: read_schema && Field.where(content_type_id: content_types.map(&:id)).exists?,
        recent_documents: recent_documents(documents, read_content),
        content_types: content_types.map { |content_type|
          content_type_ref_props(content_type).merge(entry_count: entry_counts.fetch(content_type.id, 0))
        },
        api: read_api && read_schema ? { base_path: File.join(root_path, "api") } : nil,
        permissions: {
          write_content: can?(:write, :content),
          write_schema: can?(:write, :schema)
        }
      }
    end

    private

    def recent_documents(documents, read_content)
      return [] unless read_content

      documents.includes(:content_type).order(updated_at: :desc).limit(8).map { |document|
        document_props(document).merge(
          content_type_name: document.content_type.name,
          updated_at: document.updated_at.iso8601
        )
      }
    end
  end
end
