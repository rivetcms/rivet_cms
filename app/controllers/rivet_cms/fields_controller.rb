module RivetCms
  class FieldsController < ApplicationController
    before_action -> { authorize! :delete, :schema }, only: [ :destroy ]
    before_action -> { authorize! :write, :schema }, except: [ :destroy ]
    before_action :set_owner
    before_action :set_field, only: [ :update, :destroy, :toggle_width, :unpair, :pair ]

    def create
      field = @owner.fields.build(field_params)
      field.organization = @owner.organization

      if field.save
        redirect_to owner_path, notice: "Field created"
      else
        redirect_to owner_path, inertia: { errors: field.errors }
      end
    end

    def update
      if @field.update(field_params)
        redirect_to owner_path, notice: "Field updated"
      else
        redirect_to owner_path, inertia: { errors: @field.errors }
      end
    end

    def destroy
      @field.discard
      redirect_to owner_path, notice: "Field removed"
    end

    def toggle_width
      new_width = @field.width_full? ? "half" : "full"

      @field.update!(width: new_width)

      # If changed to full width, ensure it's on its own row
      if new_width == "full"
        other_fields_on_row = @owner.fields.kept.where(row: @field.row).where.not(id: @field.id)
        if other_fields_on_row.exists?
          @field.move_to_own_row!
        end
      end

      redirect_to owner_path
    end

    def unpair
      @field.unpair!
      redirect_to owner_path
    end

    def pair
      other_field = @owner.fields.find(params[:pair_with])

      # Both fields must be half-width and not already paired
      if @field.width_half? && other_field.width_half? && !@field.paired? && !other_field.paired?
        @field.pair_with!(other_field)
      end

      redirect_to owner_path
    end

    def update_layout
      @owner.fields.update_layout!(params[:rows])
      redirect_to owner_path
    end

    private

    def set_owner
      @owner = if params[:component_id]
        Current.organization.components.find(params[:component_id])
      else
        Current.organization.content_types.find(params[:content_type_id])
      end
    end

    def owner_path
      @owner.is_a?(Component) ? component_path(@owner) : content_type_path(@owner)
    end

    def set_field
      @field = @owner.fields.find(params[:id])
    end

    def field_params
      params.require(:field).permit(:key, :label, :field_type, :description, :required, :width, :min_items, :max_items, config: {})
    end
  end
end
