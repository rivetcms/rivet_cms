module RivetCms
  class FieldsController < ApplicationController
    before_action :set_content_type
    before_action :set_field, only: [:edit, :update, :destroy, :update_width]

    # GET /content_types/:content_type_id/fields
    def index
      @fields = @content_type.fields.includes(:component).order(:position)
      @field = @content_type.fields.new
    end

    # GET /content_types/:content_type_id/fields/new
    def new
      @field = @content_type.fields.new
    end

    # POST /content_types/:content_type_id/fields
    def create
      @field = @content_type.fields.new(field_params)

      if @field.save
        redirect_to content_type_fields_path(@content_type), notice: "Field was successfully created."
      else
        respond_to do |format|
          format.html { render :new, status: :unprocessable_entity }
          format.turbo_stream { 
            render turbo_stream: turbo_stream.update("field_form",
              partial: "form",
              locals: { content_type: @content_type, field: @field }
            )
          }
        end
      end
    end

    # GET /content_types/:content_type_id/fields/:id/edit
    def edit
    end

    # PATCH/PUT /content_types/:content_type_id/fields/:id
    def update
      if @field.update(field_params)
        redirect_to content_type_fields_path(@content_type), notice: "Field was successfully updated."
      else
        respond_to do |format|
          format.html { render :edit, status: :unprocessable_entity }
          format.turbo_stream { 
            render turbo_stream: turbo_stream.update("field_form",
              partial: "form",
              locals: { content_type: @content_type, field: @field }
            )
          }
        end
      end
    end

    # DELETE /content_types/:content_type_id/fields/:id
    def destroy
      @field.destroy
      redirect_to content_type_fields_path(@content_type), notice: "Field was successfully deleted."
    end

    # POST /content_types/:content_type_id/fields/update_positions
    def update_positions
      if params[:positions].present?
        ActiveRecord::Base.transaction do
          params[:positions].each do |position_data|
            field = @content_type.fields.find_by_prefix_id(position_data[:id])
            if field
              field.update!(
                position: position_data[:position],
                row_group: position_data[:row_group]
              )
            end
          end
        end
        
        render json: { success: true }
      else
        render json: { error: "No positions data provided" }, status: :bad_request
      end
    end

    # PATCH /content_types/:content_type_id/fields/:id/update_width
    def update_width
      width_value = params[:width]
      if width_value.present? && RivetCms::Field::WIDTHS.include?(width_value)
        result = @field.update_columns(width: width_value, row_group: nil)
        render json: { success: true, field: { id: @field.to_param, width: @field.width } }
      else
        render json: { error: "Invalid width value" }, status: :unprocessable_entity
      end
    end

    private

    def set_content_type
      @content_type = ContentType.find(params[:content_type_id])
    end

    def set_field
      @field = @content_type.fields.find_by_prefix_id(params[:id])
    end

    def field_params
      params.require(:field).permit(:name, :field_type, :required, :component_id, :description, :width, options: {})
    end
  end
end