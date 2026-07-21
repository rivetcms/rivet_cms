module RivetCms
  class FieldsController < ApplicationController
    before_action :set_content_type
    before_action :set_field, only: [ :update, :destroy, :toggle_width, :unpair, :pair ]

    def create
      field = @content_type.fields.build(field_params)
      field.organization = @content_type.organization

      if field.save
        redirect_to content_type_path(@content_type), notice: "Field created"
      else
        redirect_to content_type_path(@content_type), inertia: { errors: field.errors }
      end
    end

    def update
      if @field.update(field_params)
        redirect_to content_type_path(@content_type), notice: "Field updated"
      else
        redirect_to content_type_path(@content_type), inertia: { errors: @field.errors }
      end
    end

    def destroy
      @field.discard
      redirect_to content_type_path(@content_type), notice: "Field removed"
    end

    def toggle_width
      new_width = @field.width_full? ? "half" : "full"

      @field.update!(width: new_width)

      # If changed to full width, ensure it's on its own row
      if new_width == "full"
        other_fields_on_row = @content_type.fields.kept.where(row: @field.row).where.not(id: @field.id)
        if other_fields_on_row.exists?
          @field.move_to_own_row!
        end
      end

      redirect_to content_type_path(@content_type)
    end

    def unpair
      @field.unpair!
      redirect_to content_type_path(@content_type)
    end

    def pair
      other_field = @content_type.fields.find(params[:pair_with])

      # Both fields must be half-width and not already paired
      if @field.width_half? && other_field.width_half? && !@field.paired? && !other_field.paired?
        @field.pair_with!(other_field)
      end

      redirect_to content_type_path(@content_type)
    end

    def update_layout
      Field.update_layout!(params[:rows])
      redirect_to content_type_path(@content_type)
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
