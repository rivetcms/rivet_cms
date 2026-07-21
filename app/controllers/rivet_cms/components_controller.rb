module RivetCms
  class ComponentsController < ApplicationController
    include InertiaProps

    before_action :set_component, only: [ :edit, :update, :destroy ]

    def index
      render inertia: "Components/Index", props: {
        components: Component.includes(:category).map { |c| component_props(c) }
      }
    end

    def new
      render inertia: "Components/New", props: {
        categories: Category.order(:name).map { |c| category_props(c) },
        create_category_path: create_category_components_path
      }
    end

    def create
      component = Component.new(component_params)

      if component.save
        redirect_to components_path, notice: "Component created successfully"
      else
        redirect_to new_component_path, inertia: { errors: component.errors }
      end
    end

    def edit
      render inertia: "Components/Edit", props: {
        component: component_props(@component),
        categories: Category.order(:name).map { |c| category_props(c) },
        create_category_path: create_category_components_path
      }
    end

    def update
      if @component.update(component_params)
        redirect_to components_path, notice: "Component updated successfully"
      else
        redirect_to edit_component_path(@component), inertia: { errors: @component.errors }
      end
    end

    def destroy
      @component.destroy
      redirect_to components_path, notice: "Component deleted"
    end

    def create_category
      category = Category.new(category_params)
      category.slug = category.name.to_s.parameterize if category.slug.blank?
      category.system = false if category.system.nil?

      if category.save
        render json: { id: category.id, name: category.name }
      else
        render json: { errors: category.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def set_component
      @component = Component.find(params[:id])
    end

    def component_params
      params.require(:component).permit(:name, :slug, :description, :repeatable, :category_id)
    end

    def category_params
      params.require(:category).permit(:name)
    end
  end
end
