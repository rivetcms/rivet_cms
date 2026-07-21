import { useForm } from "@inertiajs/react"
import FieldTypeIcon from "./FieldTypeIcon"
import FieldOptions from "./FieldOptions"

export default function FieldForm({ contentType, field, fieldTypes, referenceTargets, embeddableComponents, onClose }) {
  const isNew = !field

  const form = useForm({
    field_type: field?.field_type || "string",
    name: field?.name || "",
    description: field?.description || "",
    width: field?.width || "full",
    required: field?.required || false,
    options: field?.options || {},
  })

  const errorMessages = Object.entries(form.errors).flatMap(([attr, messages]) => {
    const list = Array.isArray(messages) ? messages : [messages]
    return list.map((m) => (attr === "base" ? m : `${attr.replace(/_/g, " ")} ${m}`.replace(/^./, (c) => c.toUpperCase())))
  })

  const submit = (e) => {
    e.preventDefault()
    form.transform((data) => ({ field: data }))
    const opts = { preserveScroll: true, onSuccess: onClose }
    if (isNew) {
      form.post(contentType.paths.fields, opts)
    } else {
      form.put(field.paths.update, opts)
    }
  }

  return (
    <form onSubmit={submit} className="space-y-6">
      {errorMessages.length > 0 && (
        <div className="alert alert-error text-sm">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10"/><path d="m15 9-6 6"/><path d="m9 9 6 6"/></svg>
          <div>
            {errorMessages.map((msg, i) => <p key={i}>{msg}</p>)}
          </div>
        </div>
      )}

      {isNew ? (
        <div className="form-control">
          <label className="label font-medium">Field Type</label>
          <div className="grid grid-cols-2 gap-2">
            {Object.entries(fieldTypes).map(([value, label]) => (
              <label key={value} className="cursor-pointer">
                <input
                  type="radio"
                  name="field_type"
                  value={value}
                  checked={form.data.field_type === value}
                  onChange={() => form.setData("field_type", value)}
                  className="peer hidden"
                />
                <div className="flex items-center gap-2.5 p-3 rounded-lg border-2 border-base-300 bg-base-100 transition-all peer-checked:border-primary peer-checked:bg-primary/5 hover:border-base-content/20">
                  <FieldTypeIcon fieldType={value} />
                  <span className="text-sm font-medium">{label}</span>
                </div>
              </label>
            ))}
          </div>
        </div>
      ) : (
        <div className="flex items-center gap-3 p-4 bg-base-200 rounded-lg">
          <div className="w-10 h-10 rounded-lg bg-base-100 flex items-center justify-center">
            <FieldTypeIcon fieldType={field.field_type} />
          </div>
          <div>
            <div className="font-medium">{field.field_type_label}</div>
            <div className="text-xs text-base-content/50">Field type cannot be changed</div>
          </div>
        </div>
      )}

      <div className="divider my-2"></div>

      <div className="form-control">
        <label className="label" htmlFor="field_name">Name</label>
        <input
          id="field_name"
          type="text"
          required
          autoFocus={isNew}
          placeholder="e.g., Title, Author, Featured Image"
          className="input input-bordered w-full"
          value={form.data.name}
          onChange={(e) => form.setData("name", e.target.value)}
        />
        <label className="label">
          <span className="label-text-alt text-base-content/50">The label shown to content editors</span>
        </label>
      </div>

      <div className="form-control">
        <label className="label" htmlFor="field_description">Help Text</label>
        <textarea
          id="field_description"
          rows={2}
          placeholder="Instructions or guidelines for editors"
          className="textarea textarea-bordered w-full"
          value={form.data.description || ""}
          onChange={(e) => form.setData("description", e.target.value)}
        />
        <label className="label">
          <span className="label-text-alt text-base-content/50">Shown below the field when editing content</span>
        </label>
      </div>

      <div className="form-control">
        <label className="label">Layout Width</label>
        <div className="grid grid-cols-2 gap-3">
          <label className="cursor-pointer">
            <input
              type="radio"
              name="width"
              value="full"
              checked={form.data.width === "full"}
              onChange={() => form.setData("width", "full")}
              className="peer hidden"
            />
            <div className="border-2 border-base-300 rounded-lg p-4 text-center transition-all peer-checked:border-primary peer-checked:bg-primary/5">
              <div className="h-3 bg-base-300 rounded mb-3"></div>
              <span className="text-sm font-medium">Full width</span>
            </div>
          </label>
          <label className="cursor-pointer">
            <input
              type="radio"
              name="width"
              value="half"
              checked={form.data.width === "half"}
              onChange={() => form.setData("width", "half")}
              className="peer hidden"
            />
            <div className="border-2 border-base-300 rounded-lg p-4 text-center transition-all peer-checked:border-primary peer-checked:bg-primary/5">
              <div className="flex gap-2 mb-3">
                <div className="flex-1 h-3 bg-base-300 rounded"></div>
                <div className="flex-1 h-3 bg-base-200 rounded"></div>
              </div>
              <span className="text-sm font-medium">Half width</span>
            </div>
          </label>
        </div>
      </div>

      <div className="form-control">
        <label className="label cursor-pointer justify-start gap-4 p-4 bg-base-200/50 rounded-lg hover:bg-base-200 transition-colors">
          <input
            type="checkbox"
            className="checkbox checkbox-primary"
            checked={form.data.required}
            onChange={(e) => form.setData("required", e.target.checked)}
          />
          <div>
            <span className="font-medium">Required field</span>
            <p className="text-base-content/50 text-sm mt-0.5">Content cannot be saved without this field</p>
          </div>
        </label>
      </div>

      {!isNew && (
        <>
          <div className="divider my-2">
            <span className="text-xs text-base-content/40 uppercase tracking-wider">Options</span>
          </div>
          <FieldOptions
            fieldType={field.field_type}
            options={form.data.options}
            setOption={(key, value) => form.setData("options", { ...form.data.options, [key]: value })}
            referenceTargets={referenceTargets}
            embeddableComponents={embeddableComponents}
          />
        </>
      )}

      <div className="flex justify-end gap-3 pt-4 border-t border-base-200">
        <button type="button" className="btn btn-ghost" onClick={onClose}>
          Cancel
        </button>
        <button type="submit" className="btn btn-primary" disabled={form.processing}>
          {isNew ? "Add Field" : "Save Changes"}
        </button>
      </div>
    </form>
  )
}
