import { useRef } from "react"
import { Link, useForm, usePage } from "@inertiajs/react"
import { slugFromName, cleanSlug } from "../lib/slug"
import { TextInput, TextArea, ToggleField, FormActions } from "./forms"

export default function ContentTypeForm({ contentType, submitLabel }) {
  const { paths } = usePage().props
  // Once the user edits the slug by hand, stop auto-generating it from the name
  const slugTouched = useRef(false)

  const form = useForm({
    name: contentType?.name || "",
    slug: contentType?.slug || "",
    description: contentType?.description || "",
    single: contentType?.single || false,
  })

  const syncSlug = (name, single) => {
    if (slugTouched.current) return
    form.setData((data) => ({ ...data, slug: slugFromName(name, { singular: single }) }))
  }

  const submit = (e) => {
    e.preventDefault()
    form.transform((data) => ({ content_type: data }))
    if (contentType?.paths?.update) {
      form.put(contentType.paths.update)
    } else {
      form.post(paths.content_types)
    }
  }

  return (
    <form onSubmit={submit} className="space-y-5">
      <TextInput
        id="content_type_name"
        label="Name"
        required
        error={form.errors.name}
        value={form.data.name}
        onChange={(e) => {
          const name = e.target.value
          form.setData("name", name)
          syncSlug(name, form.data.single)
        }}
      />
      <TextInput
        id="content_type_slug"
        label="Slug"
        required
        className="font-mono text-[13px]"
        hint="Used in API endpoints and URLs"
        error={form.errors.slug}
        value={form.data.slug}
        onChange={(e) => {
          slugTouched.current = true
          form.setData("slug", cleanSlug(e.target.value))
        }}
      />
      <TextArea
        id="content_type_description"
        label="Description"
        rows={3}
        error={form.errors.description}
        value={form.data.description || ""}
        onChange={(e) => form.setData("description", e.target.value)}
      />
      <ToggleField
        label="Single Entry"
        description="A single type holds one entry; a collection type holds many."
        checked={form.data.single}
        onChange={(single) => {
          form.setData("single", single)
          syncSlug(form.data.name, single)
        }}
      />
      <FormActions>
        <Link href={paths.content_types} className="btn btn-ghost">Cancel</Link>
        <button type="submit" className="btn btn-primary" disabled={form.processing}>
          {submitLabel}
        </button>
      </FormActions>
    </form>
  )
}
