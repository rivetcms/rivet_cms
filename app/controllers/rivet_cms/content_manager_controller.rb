module RivetCms
  class ContentManagerController < ApplicationController
    include InertiaProps

    def index
      content_types = Current.organization.content_types.order(:name)
      documents = Document.where(organization: Current.organization).order(updated_at: :desc)
      if params[:type].present?
        documents = documents.joins(:content_type).where(rivet_cms_content_types: { slug: params[:type] })
      end
      documents = documents.search(params[:q]) if params[:q].present?
      page = documents.includes(:draft_revision, :content_type).page(params[:page]).per(25)
      titles = document_titles(page)

      render inertia: "ContentManager/Index", props: {
        content_types: content_types.map { |content_type| content_type_props(content_type) },
        documents: page.map { |document|
          document_list_props(document, titles).merge(
            content_type_name: document.content_type.name,
            content_type_slug: document.content_type.slug
          )
        },
        q: params[:q].presence,
        type: params[:type].presence,
        pagination: { page: page.current_page, total_pages: page.total_pages }
      }
    end
  end
end
