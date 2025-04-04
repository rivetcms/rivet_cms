module RivetCms
  class ContentTypesController < ApplicationController
    before_action :set_content_type, only: [:show, :edit, :update, :destroy]

    def index
      @content_types = ContentType.order(:name)
    end

    def show
      @contents = @content_type.contents.order(created_at: :desc).limit(10)
    end

    def new
      @content_type = ContentType.new
    end

    def edit
    end

    def create
      @content_type = ContentType.new(content_type_params)

      if @content_type.save
        redirect_to @content_type, notice: 'Content type was successfully created.'
      else
        respond_to do |format|
          format.html { render :new, status: :unprocessable_entity }
          format.turbo_stream { 
            render turbo_stream: turbo_stream.update("content_type_form",
              partial: "form",
              locals: { content_type: @content_type }
            )
          }
        end
      end
    end

    def update
      if @content_type.update(content_type_params)
        redirect_to @content_type, notice: 'Content type was successfully updated.'
      else
        render :edit
      end
    end

    def destroy
      @content_type.destroy
      redirect_to content_types_url, notice: 'Content type was successfully destroyed.'
    end

    private

    def set_content_type
      @content_type = ContentType.find(params[:id])
    end

    def content_type_params
      params.require(:content_type).permit(:name, :slug, :description, :is_single)
    end
  end
end 