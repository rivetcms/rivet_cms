module RivetCms
  class FieldsController < ApplicationController
    before_action -> { authorize! :delete, :schema }, only: [ :destroy ]
    before_action -> { authorize! :write, :schema }, except: [ :destroy ]
    before_action :set_owner
    before_action :set_field, only: [ :update, :destroy, :toggle_width, :unpair, :pair ]
    # Record layer: every field action touches its owner's schema, so the
    # owner is checked for all of them, verb-matched like entries: writes
    # need :write on the owner, destroy needs :delete. Denying a type or
    # component denies its fields even on a direct URL.
    before_action -> { authorize! :write, :schema, record: @owner }, except: [ :destroy ]
    before_action -> { authorize! :delete, :schema, record: @owner }, only: [ :destroy ]
    before_action -> { authorize! :write, :schema, record: @field }, only: [ :update, :toggle_width, :unpair, :pair ]
    before_action -> { authorize! :delete, :schema, record: @field }, only: [ :destroy ]

    def create
      field = @owner.fields.build(field_params)
      field.organization = @owner.organization

      if field.save
        audit "field.created", field
        redirect_to owner_path, notice: "Field created"
      else
        redirect_to owner_path, inertia: { errors: field.errors }
      end
    end

    def update
      if @field.update(field_params)
        audit "field.updated", @field
        redirect_to owner_path, notice: "Field updated"
      else
        redirect_to owner_path, inertia: { errors: @field.errors }
      end
    end

    def destroy
      @field.discard
      audit "field.removed", @field
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

      audit "field.updated", @field, change: "layout"
      redirect_to owner_path
    end

    def unpair
      @field.unpair!
      audit "field.updated", @field, change: "layout"
      redirect_to owner_path
    end

    def pair
      other_field = @owner.fields.find(params[:pair_with])
      # Pairing mutates both fields, so both must pass the record phase
      authorize! :write, :schema, record: other_field

      # Both fields must be half-width and not already paired
      if @field.width_half? && other_field.width_half? && !@field.paired? && !other_field.paired?
        @field.pair_with!(other_field)
        audit "field.updated", @field, change: "layout"
      end

      redirect_to owner_path
    end

    def update_layout
      # The bulk update touches every referenced field, so each must pass the
      # record phase, not just the owner
      moved = @owner.fields.where(id: Array(params[:rows]).flatten)
      moved.each { |field| authorize! :write, :schema, record: field }
      @owner.fields.update_layout!(params[:rows])
      audit "schema.layout_updated", @owner
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
