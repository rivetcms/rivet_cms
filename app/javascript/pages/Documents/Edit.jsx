import { Link, useForm, router } from "@inertiajs/react"
import PageHeader from "../../components/PageHeader"
import { TextInput, FormActions } from "../../components/forms"
import FieldGrid from "../../components/entries/FieldGrid"
import { cleanSlug } from "../../lib/slug"

const FILE_TYPES = ["image", "video", "file"]

export default function Edit({ content_type: contentType, fields, document, values, reference_options: referenceOptions, form_paths: formPaths }) {
  const isNew = !document

  const form = useForm({
    slug: document?.slug || "",
    values: values || {},
  })

  const setValue = (key, value) => form.setData("values", { ...form.data.values, [key]: value })

  const hasFile = fields.some((f) => FILE_TYPES.includes(f.field_type) && form.data.values[f.key] instanceof File)

  const errorMessages = Object.entries(form.errors).flatMap(([attr, messages]) => {
    const list = Array.isArray(messages) ? messages : [messages]
    return list.map((m) => (attr === "base" ? m : `${attr.replace(/_/g, " ")} ${m}`.replace(/^./, (c) => c.toUpperCase())))
  })

  const submit = (e) => {
    e.preventDefault()
    const opts = { preserveScroll: true, forceFormData: hasFile }
    if (isNew) {
      form.post(formPaths.create, opts)
    } else {
      form.transform((data) => ({ values: data.values, slug: data.slug }))
      form.patch(document.paths.update, opts)
    }
  }

  // Publish saves the on-screen values first so unsaved edits are validated.
  const publish = () => router.post(document.paths.publish, { values: form.data.values }, { preserveScroll: true, forceFormData: hasFile })
  const destroy = () => {
    if (confirm("Move this entry to the trash? You can restore it later.")) router.delete(document.paths.destroy)
  }

  return (
    <>
      <div className="mb-4">
        <Link href={formPaths.index} className="inline-flex items-center gap-1.5 text-[13px] font-medium text-base-content/50 transition-colors hover:text-base-content">
          <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m12 19-7-7 7-7"/><path d="M19 12H5"/></svg>
          {contentType.name} entries
        </Link>
      </div>

      <PageHeader
        title={isNew ? "New Entry" : document.slug}
        meta={!isNew && (
          <span className={`badge badge-sm font-medium ${document.published ? "badge-success badge-soft" : "badge-ghost"}`}>
            {document.published ? "Published" : "Draft"}
          </span>
        )}
      >
        {!isNew && (
          <>
            <button type="button" className="btn btn-ghost border border-base-300 text-error" onClick={destroy}>Delete</button>
            <button type="button" className="btn btn-primary" onClick={publish}>Publish</button>
          </>
        )}
      </PageHeader>

      <form onSubmit={submit} className="space-y-5 rounded-box border border-base-300 bg-base-100 p-5">
        {errorMessages.length > 0 && (
          <div className="alert alert-error px-3 py-2.5 text-[13px]">
            <div>{errorMessages.map((msg, i) => <p key={i}>{msg}</p>)}</div>
          </div>
        )}

        <TextInput
          label="Slug"
          required
          hint="Unique identifier for this entry within the content type"
          value={form.data.slug}
          onChange={(e) => form.setData("slug", cleanSlug(e.target.value))}
        />

        <FieldGrid
          fields={fields}
          values={form.data.values}
          setValue={setValue}
          referenceOptions={referenceOptions}
          errors={form.errors}
        />

        <FormActions>
          <Link href={formPaths.index} className="btn btn-ghost">Cancel</Link>
          <button type="submit" className="btn btn-primary" disabled={form.processing}>Save Draft</button>
        </FormActions>
      </form>
    </>
  )
}
