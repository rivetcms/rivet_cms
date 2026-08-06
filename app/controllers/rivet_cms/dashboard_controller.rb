module RivetCms
  class DashboardController < ApplicationController
    include InertiaProps

    def show
      organization = Current.organization
      content_types = organization.content_types.order(:name).to_a
      documents = Document.where(organization: organization)
      entry_counts = documents.group(:content_type_id).count

      render inertia: "Dashboard/Show", props: {
        stats: {
          entries: documents.count,
          content_types: content_types.size,
          components: organization.components.count,
          media_assets: organization.media_assets.count,
          api_tokens: organization.api_tokens.count
        },
        has_fields: Field.where(content_type_id: content_types.map(&:id)).exists?,
        recent_documents: documents.includes(:content_type).order(updated_at: :desc).limit(8).map { |document|
          document_props(document).merge(
            content_type_name: document.content_type.name,
            updated_at: document.updated_at.iso8601
          )
        },
        content_types: content_types.map { |content_type|
          content_type_props(content_type).merge(entry_count: entry_counts.fetch(content_type.id, 0))
        },
        api: { base_path: File.join(root_path, "api") }
      }
    end
  end
end
