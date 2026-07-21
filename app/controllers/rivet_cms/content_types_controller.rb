module RivetCms
  class ContentTypesController < ApplicationController
    include InertiaProps

    before_action :set_content_type, only: [ :show, :edit, :update, :destroy ]

    def index
      render inertia: "ContentTypes/Index", props: {
        content_types: ContentType.all.map { |ct| content_type_props(ct) }
      }
    end

    def show
      fields = @content_type.fields.kept.ordered

      render inertia: "ContentTypes/Show", props: {
        content_type: content_type_props(@content_type),
        fields: fields.map { |f| field_props(f) },
        field_types: Field::FIELD_TYPE_LABELS,
        # Selectable targets for "reference" and "component" field options
        reference_targets: ContentType.where.not(id: @content_type.id).order(:name).map { |ct| { id: ct.id, name: ct.name } },
        embeddable_components: Component.order(:name).map { |c| { id: c.id, name: c.name } }
      }
    end

    def new
      render inertia: "ContentTypes/New"
    end

    def create
      content_type = ContentType.new(content_type_params)

      if content_type.save
        redirect_to content_type_path(content_type), notice: "Content type created successfully"
      else
        redirect_to new_content_type_path, inertia: { errors: content_type.errors }
      end
    end

    def edit
      render inertia: "ContentTypes/Edit", props: {
        content_type: content_type_props(@content_type)
      }
    end

    def update
      if @content_type.update(content_type_params)
        redirect_to content_type_path(@content_type), notice: "Content type updated successfully"
      else
        redirect_to edit_content_type_path(@content_type), inertia: { errors: @content_type.errors }
      end
    end

    def destroy
      @content_type.destroy
      redirect_to content_types_path, notice: "Content type deleted"
    end

    private

    def set_content_type
      @content_type = ContentType.find(params[:id])
    end

    def content_type_params
      params.require(:content_type).permit(:name, :slug, :description, :single)
    end
  end
end
