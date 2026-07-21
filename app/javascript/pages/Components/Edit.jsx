import ComponentForm from "../../components/ComponentForm"

export default function Edit({ component, categories, create_category_path: createCategoryPath }) {
  return (
    <div className="max-w-2xl mx-auto">
      <h1 className="text-xl font-semibold mb-8">Edit {component.name}</h1>
      <ComponentForm
        component={component}
        categories={categories}
        createCategoryPath={createCategoryPath}
        submitLabel="Update Component"
      />
    </div>
  )
}
