import { Link, useForm, usePage } from "@inertiajs/react"
import CategoryCombobox from "./CategoryCombobox"
import { FieldError } from "./FormErrors"

export default function ComponentForm({ component, categories, createCategoryPath, submitLabel }) {
  const { paths } = usePage().props

  const form = useForm({
    name: component?.name || "",
    description: component?.description || "",
    category_id: component?.category_id || null,
    repeatable: component?.repeatable || false,
  })

  const submit = (e) => {
    e.preventDefault()
    form.transform((data) => ({ component: data }))
    if (component?.paths?.update) {
      form.put(component.paths.update)
    } else {
      form.post(paths.components)
    }
  }

  return (
    <form onSubmit={submit} className="space-y-6">
      <div className="form-control w-full">
        <label className="label" htmlFor="component_name">Name</label>
        <input
          id="component_name"
          type="text"
          required
          className="input input-bordered w-full"
          value={form.data.name}
          onChange={(e) => form.setData("name", e.target.value)}
        />
        <FieldError error={form.errors.name} />
      </div>
      <div className="form-control w-full">
        <label className="label" htmlFor="component_description">Description</label>
        <textarea
          id="component_description"
          className="textarea textarea-bordered w-full"
          rows={3}
          value={form.data.description || ""}
          onChange={(e) => form.setData("description", e.target.value)}
        />
        <FieldError error={form.errors.description} />
      </div>
      <div className="form-control w-full">
        <label className="label">Category</label>
        <CategoryCombobox
          categories={categories}
          value={form.data.category_id}
          onChange={(id) => form.setData("category_id", id)}
          createPath={createCategoryPath}
        />
        <FieldError error={form.errors.category} />
      </div>
      <div className="form-control">
        <label className="label cursor-pointer justify-start gap-4">
          <input
            type="checkbox"
            className="checkbox checkbox-primary"
            checked={form.data.repeatable}
            onChange={(e) => form.setData("repeatable", e.target.checked)}
          />
          <span className="label-text">Repeatable</span>
        </label>
        <p className="text-base-content/60 text-sm ml-10">
          If checked, this will be a repeatable component (multiple entries). If unchecked, it will be a single component (one entry).
        </p>
      </div>
      <div className="flex justify-end gap-3 pt-6">
        <Link href={paths.components} className="btn btn-outline">Cancel</Link>
        <button type="submit" className="btn btn-primary" disabled={form.processing}>
          {submitLabel}
        </button>
      </div>
    </form>
  )
}
