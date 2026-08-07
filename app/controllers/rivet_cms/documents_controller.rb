module RivetCms
  class DocumentsController < ApplicationController
    include InertiaProps

    before_action -> { authorize! :read, :content }, only: [ :index, :edit, :new ]
    before_action -> { authorize! :write, :content }, except: [ :index, :edit, :publish, :destroy ]
    before_action -> { authorize! :publish, :content }, only: [ :publish ]
    before_action -> { authorize! :delete, :content }, only: [ :destroy ]
    before_action :set_content_type
    before_action :set_document, only: [ :edit, :update, :destroy, :publish ]

    def index
      documents = @content_type.documents.recent
      documents = documents.search(params[:q]) if params[:q].present?
      page = documents.includes(:draft_revision).page(params[:page]).per(25)

      titles = document_titles(page)

      render inertia: "Documents/Index", props: {
        content_type: content_type_props(@content_type),
        q: params[:q].presence,
        documents: page.map { |document| document_list_props(document, titles) },
        pagination: { page: page.current_page, total_pages: page.total_pages }
      }
    end

    def new
      render inertia: "Documents/Edit", props: editor_props(nil)
    end

    def create
      document = @content_type.documents.new(slug: params[:slug])
      document.save!
      draft = document.revisions.create!(state: :draft, **author_attributes)
      document.update!(draft_revision: draft)
      DraftWriter.new(draft).write(values_param)

      redirect_to edit_content_type_document_path(@content_type, document), notice: "Draft saved"
    rescue ActiveRecord::RecordInvalid => e
      redirect_to new_content_type_document_path(@content_type), inertia: { errors: e.record.errors }
    end

    def edit
      render inertia: "Documents/Edit", props: editor_props(@document)
    end

    def update
      @document.draft_revision.update!(author_attributes)
      DraftWriter.new(@document.draft_revision).write(values_param)
      redirect_to edit_content_type_document_path(@content_type, @document), notice: "Draft saved"
    end

    # Publishes what's on screen: the submitted values are written to the
    # draft first, so unsaved edits are validated instead of the stale draft.
    def publish
      draft = @document.draft_revision
      if params.key?(:values)
        draft.update!(author_attributes)
        DraftWriter.new(draft).write(values_param)
      end
      # The snapshot records who published, which is not always the last editor
      draft.publish!(publisher: author_attributes[:author], publisher_name: author_attributes[:author_name])
      redirect_to edit_content_type_document_path(@content_type, @document), notice: "Published"
    rescue ContentInvalidError => e
      redirect_to edit_content_type_document_path(@content_type, @document),
                  inertia: { errors: e.errors.group_by(&:field_key).transform_values { |group| group.map(&:message) } }
    end

    def destroy
      @document.destroy
      redirect_to content_type_documents_path(@content_type), notice: "Entry deleted"
    end

    private

    def set_content_type
      @content_type = Current.organization.content_types.find(params[:content_type_id])
    end

    def set_document
      @document = @content_type.documents.find(params[:id])
    end

    def editor_props(document)
      {
        content_type: content_type_props(@content_type),
        fields: @content_type.fields.kept.ordered.map { |field| entry_field_props(field) },
        document: document ? document_props(document) : nil,
        values: document ? draft_values(document.draft_revision) : {},
        reference_options: reference_options,
        form_paths: { index: content_type_documents_path(@content_type), create: content_type_documents_path(@content_type) }
      }
    end

    def reference_options
      Document.where(organization: Current.organization).recent
              .map { |document| { id: document.id, slug: document.slug, content_type: document.content_type.name } }
    end

    def values_param
      params.fetch(:values, {}).permit!.to_h
    end

    # Content is always attributed. With a signed-in user it's their name;
    # without one (unconfigured/programmatic) it falls back to "System".
    def author_attributes
      @author_attributes ||= begin
        user = Current.user
        { author: user, author_name: user ? RivetCms.user_name.call(user).presence || "System" : "System" }
      end
    end
  end
end
