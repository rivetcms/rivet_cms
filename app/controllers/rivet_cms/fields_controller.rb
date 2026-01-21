module RivetCms
  class FieldsController < ApplicationController
    layout false # Forms are loaded into drawer, no layout needed

    before_action :set_content_type
    before_action :set_field, only: [:edit, :update, :destroy, :toggle_width, :unpair, :pair]

    def index
      @fields = @content_type.fields.ordered
    end

    def new
      @field = @content_type.fields.build
    end

    def create
      @field = @content_type.fields.build(field_params)
      @field.organization = @content_type.organization

      if @field.save
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to content_type_path(@content_type), notice: "Field created" }
        end
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @field.update(field_params)
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to content_type_path(@content_type), notice: "Field updated" }
        end
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @field.discard

      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.remove(@field) }
        format.html { redirect_to content_type_path(@content_type), notice: "Field removed" }
      end
    end

    def toggle_width
      new_width = @field.width_full? ? "half" : "full"

      @field.update!(width: new_width)

      # If changed to full width, ensure it's on its own row
      if new_width == "full"
        # Check if there are other fields on the same row
        other_fields_on_row = @content_type.fields.kept.where(row: @field.row).where.not(id: @field.id)
        if other_fields_on_row.exists?
          @field.move_to_own_row!
        end
      end

      respond_to do |format|
        format.turbo_stream { redirect_to content_type_path(@content_type), status: :see_other }
        format.html { redirect_to content_type_path(@content_type) }
      end
    end

    def unpair
      @field.unpair!

      respond_to do |format|
        format.turbo_stream { redirect_to content_type_path(@content_type), status: :see_other }
        format.html { redirect_to content_type_path(@content_type) }
      end
    end

    def pair
      other_field = @content_type.fields.find(params[:pair_with])

      # Both fields must be half-width and not already paired
      if @field.width_half? && other_field.width_half? && !@field.paired? && !other_field.paired?
        @field.pair_with!(other_field)
      end

      respond_to do |format|
        format.turbo_stream { redirect_to content_type_path(@content_type), status: :see_other }
        format.html { redirect_to content_type_path(@content_type) }
      end
    end

    def update_layout
      rows_config = params[:rows]
      Field.update_layout!(rows_config)

      head :ok
    end

    private

    def set_content_type
      @content_type = ContentType.find(params[:content_type_id])
    end

    def set_field
      @field = @content_type.fields.find(params[:id])
    end

    def field_params
      params.require(:field).permit(:name, :field_type, :description, :required, :width, options: {})
    end
  end
end
