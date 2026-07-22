import { Link, useForm, usePage } from "@inertiajs/react"
import CategoryCombobox from "./CategoryCombobox"
import { Field, TextInput, TextArea, FormActions } from "./forms"

export default function ComponentForm({ component, categories, createCategoryPath, submitLabel, onCancel }) {
  const { paths } = usePage().props

  const form = useForm({
    name: component?.name || "",
    description: component?.description || "",
    category_id: component?.category_id || null,
  })

  // In modal mode, keep the modal open when validation fails and close on success
  const modalOpts = onCancel
    ? { preserveScroll: true, preserveState: (page) => Object.keys(page.props.errors || {}).length > 0, onSuccess: onCancel }
    : {}

  const submit = (e) => {
    e.preventDefault()
    form.transform((data) => ({ component: data }))
    if (component?.paths?.update) {
      form.put(component.paths.update, modalOpts)
    } else {
      form.post(paths.components, modalOpts)
    }
  }

  return (
    <form onSubmit={submit} className="space-y-5">
      <TextInput
        id="component_name"
        label="Name"
        required
        error={form.errors.name}
        value={form.data.name}
        onChange={(e) => form.setData("name", e.target.value)}
      />
      <TextArea
        id="component_description"
        label="Description"
        rows={3}
        error={form.errors.description}
        value={form.data.description || ""}
        onChange={(e) => form.setData("description", e.target.value)}
      />
      <Field label="Category" error={form.errors.category}>
        <CategoryCombobox
          categories={categories}
          value={form.data.category_id}
          onChange={(id) => form.setData("category_id", id)}
          createPath={createCategoryPath}
        />
      </Field>
      <FormActions>
        {onCancel ? (
          <button type="button" className="btn btn-ghost" onClick={onCancel}>Cancel</button>
        ) : (
          <Link href={paths.components} className="btn btn-ghost">Cancel</Link>
        )}
        <button type="submit" className="btn btn-primary" disabled={form.processing}>
          {submitLabel}
        </button>
      </FormActions>
    </form>
  )
}
