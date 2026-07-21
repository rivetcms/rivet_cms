import PageHeader from "../../components/PageHeader"
import ComponentForm from "../../components/ComponentForm"

export default function Edit({ component, categories, create_category_path: createCategoryPath }) {
  return (
    <div className="mx-auto max-w-2xl">
      <PageHeader title={`Edit ${component.name}`} description="Update this component's settings." />
      <div className="rounded-box border border-base-300 bg-base-100 p-6">
        <ComponentForm
          component={component}
          categories={categories}
          createCategoryPath={createCategoryPath}
          submitLabel="Save Changes"
        />
      </div>
    </div>
  )
}
