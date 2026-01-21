module RivetCms
  class ContentTypesController < ApplicationController
    before_action :set_content_type, only: [ :show, :edit, :update, :destroy ]

    def index
      @content_types = ContentType.all
    end

    def show
      @fields = @content_type.fields.kept.ordered
    end

    def new
      @content_type = ContentType.new
    end

    def create
      @content_type = ContentType.new(content_type_params)

      if @content_type.save
        redirect_to content_type_path(@content_type), notice: "Content type created successfully"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @content_type.update(content_type_params)
        redirect_to content_type_path(@content_type), notice: "Content type updated successfully"
      else
        render :edit, status: :unprocessable_entity
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
