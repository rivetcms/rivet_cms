module RivetCms
  class ComponentsController < ApplicationController
    def index
      @components = Component.all
    end

    def new
      @component = Component.new
      @categories = Category.all.order(:name)
    end

    def create
      @component = Component.new(component_params)
      # Handle category_id from either the Rails form field or Basecoat's hidden input
      category_id = params[:component][:category_id].presence || params["category-combobox-value"].presence
      @component.category_id = category_id if category_id

      if @component.save
        redirect_to components_path, notice: "Component created successfully"
      else
        @categories = Category.all.order(:name)
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @component = Component.find(params[:id])
      @categories = Category.all.order(:name)
    end

    private

    def component_params
      params.require(:component).permit(:name, :slug, :description, :repeatable, :category_id)
    end
  end
end
