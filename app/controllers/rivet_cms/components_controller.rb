module RivetCms
  class ComponentsController < ApplicationController
    include InertiaProps

    before_action :set_component, only: [ :show, :update, :destroy ]

    def index
      field_counts = Field.where(component_id: Current.organization.components.select(:id)).group(:component_id).count

      render inertia: "Components/Index", props: {
        components: Current.organization.components.includes(:category).map { |c|
          component_props(c).merge(fields_count: field_counts.fetch(c.id, 0))
        }
      }
    end

    def new
      render inertia: "Components/New", props: {
        categories: Current.organization.categories.order(:name).map { |c| category_props(c) },
        create_category_path: create_category_components_path
      }
    end

    def create
      component = Component.new(component_params)

      if component.save
        redirect_to component_path(component), notice: "Component created successfully"
      else
        redirect_to new_component_path, inertia: { errors: component.errors }
      end
    end

    def show
      render inertia: "Components/Show", props: {
        component: component_props(@component),
        categories: Current.organization.categories.order(:name).map { |c| category_props(c) },
        create_category_path: create_category_components_path,
        fields: @component.fields.kept.ordered.map { |f| field_props(f) },
        field_types: Field::FIELD_TYPE_LABELS.except("component"),
        reference_targets: Current.organization.content_types.order(:name).map { |ct| { id: ct.id, name: ct.name } },
        embeddable_components: []
      }
    end

    def update
      if @component.update(component_params)
        redirect_to component_path(@component), notice: "Component updated successfully"
      else
        redirect_to component_path(@component), inertia: { errors: @component.errors }
      end
    end

    def destroy
      @component.destroy
      redirect_to components_path, notice: "Component deleted"
    rescue ActiveRecord::InvalidForeignKey
      redirect_to components_path, alert: "Component is in use and cannot be deleted"
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
      @component = Current.organization.components.find(params[:id])
    end

    def component_params
      params.require(:component).permit(:name, :slug, :description, :category_id)
    end

    def category_params
      params.require(:category).permit(:name)
    end
  end
end
