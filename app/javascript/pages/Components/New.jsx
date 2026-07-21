import ComponentForm from "../../components/ComponentForm"

export default function New({ categories, create_category_path: createCategoryPath }) {
  return (
    <div className="max-w-2xl mx-auto">
      <h1 className="text-xl font-semibold mb-8">New Component</h1>
      <ComponentForm categories={categories} createCategoryPath={createCategoryPath} submitLabel="Create Component" />
    </div>
  )
}
