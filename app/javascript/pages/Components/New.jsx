import PageHeader from "../../components/PageHeader"
import ComponentForm from "../../components/ComponentForm"

export default function New({ categories, create_category_path: createCategoryPath }) {
  return (
    <div className="mx-auto max-w-2xl">
      <PageHeader title="New Component" description="Create a reusable block for your content types." />
      <div className="rounded-box border border-base-300 bg-base-100 p-6">
        <ComponentForm categories={categories} createCategoryPath={createCategoryPath} submitLabel="Create Component" />
      </div>
    </div>
  )
}
