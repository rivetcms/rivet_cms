import { useRef } from "react"
import { Link, useForm, usePage } from "@inertiajs/react"
import { slugFromName, cleanSlug } from "../lib/slug"
import { FieldError } from "./FormErrors"

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
    if (contentType?.paths?.update) {
      form.transform((data) => ({ content_type: data }))
      form.put(contentType.paths.update)
    } else {
      form.transform((data) => ({ content_type: data }))
      form.post(paths.content_types)
    }
  }

  return (
    <form onSubmit={submit} className="space-y-6">
      <div className="form-control w-full">
        <label className="label" htmlFor="content_type_name">Name</label>
        <input
          id="content_type_name"
          type="text"
          required
          className="input input-bordered w-full"
          value={form.data.name}
          onChange={(e) => {
            const name = e.target.value
            form.setData("name", name)
            syncSlug(name, form.data.single)
          }}
        />
        <FieldError error={form.errors.name} />
      </div>
      <div className="form-control w-full">
        <label className="label" htmlFor="content_type_slug">Slug</label>
        <input
          id="content_type_slug"
          type="text"
          required
          className="input input-bordered w-full"
          value={form.data.slug}
          onChange={(e) => {
            slugTouched.current = true
            form.setData("slug", cleanSlug(e.target.value))
          }}
        />
        <FieldError error={form.errors.slug} />
      </div>
      <div className="form-control w-full">
        <label className="label" htmlFor="content_type_description">Description</label>
        <textarea
          id="content_type_description"
          className="textarea textarea-bordered w-full"
          rows={3}
          value={form.data.description || ""}
          onChange={(e) => form.setData("description", e.target.value)}
        />
        <FieldError error={form.errors.description} />
      </div>
      <div className="form-control">
        <label className="label cursor-pointer justify-start gap-4">
          <input
            type="checkbox"
            className="checkbox checkbox-primary"
            checked={form.data.single}
            onChange={(e) => {
              const single = e.target.checked
              form.setData("single", single)
              syncSlug(form.data.name, single)
            }}
          />
          <span className="label-text">Single Entry</span>
        </label>
        <p className="text-base-content/60 text-sm ml-10">
          If checked, this will be a single type (one entry). If unchecked, it will be a collection type (multiple entries).
        </p>
      </div>
      <div className="flex justify-end gap-3 pt-6">
        <Link href={paths.content_types} className="btn btn-outline">Cancel</Link>
        <button type="submit" className="btn btn-primary" disabled={form.processing}>
          {submitLabel}
        </button>
      </div>
    </form>
  )
}
