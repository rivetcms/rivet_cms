import { useForm } from "@inertiajs/react"
import FieldTypeIcon from "./FieldTypeIcon"
import FieldOptions from "./FieldOptions"
import { Field, TextInput, TextArea, ToggleField, RadioTile, FormActions } from "../forms"

export default function FieldForm({ owner, field, fieldTypes, referenceTargets, embeddableComponents, onClose }) {
  const isNew = !field

  const form = useForm({
    field_type: field?.field_type || "string",
    label: field?.label || "",
    description: field?.description || "",
    width: field?.width || "full",
    required: field?.required || false,
    min_items: field?.min_items ?? null,
    max_items: field?.max_items ?? null,
    config: field?.config || {},
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
      form.post(owner.paths.fields, opts)
    } else {
      form.put(field.paths.update, opts)
    }
  }

  return (
    <form onSubmit={submit} className="space-y-5">
      {errorMessages.length > 0 && (
        <div className="alert alert-error px-3 py-2.5 text-[13px]">
          <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10"/><path d="m15 9-6 6"/><path d="m9 9 6 6"/></svg>
          <div>
            {errorMessages.map((msg, i) => <p key={i}>{msg}</p>)}
          </div>
        </div>
      )}

      {isNew ? (
        <Field label="Field Type">
          <div className="grid grid-cols-2 gap-1.5">
            {Object.entries(fieldTypes).map(([value, label]) => (
              <RadioTile
                key={value}
                name="field_type"
                checked={form.data.field_type === value}
                onChange={() => form.setData("field_type", value)}
                className="flex items-center gap-2 px-2.5 py-2"
              >
                <FieldTypeIcon fieldType={value} size={14} />
                <span className="text-[13px] font-medium">{label}</span>
              </RadioTile>
            ))}
          </div>
        </Field>
      ) : (
        <div className="flex items-center gap-3 rounded-field border border-base-300 bg-base-200/50 px-3 py-2.5">
          <div className="flex size-8 items-center justify-center rounded-selector border border-base-300 bg-base-100">
            <FieldTypeIcon fieldType={field.field_type} />
          </div>
          <div>
            <div className="text-[13px] font-medium">{field.field_type_label}</div>
            <div className="text-xs text-base-content/50">Field type cannot be changed</div>
          </div>
        </div>
      )}

      <TextInput
        id="field_label"
        label="Label"
        required
        autoFocus={isNew}
        placeholder="e.g., Title, Author, Featured Image"
        hint="The label shown to content editors; the API key is derived from it"
        value={form.data.label}
        onChange={(e) => form.setData("label", e.target.value)}
      />

      <TextArea
        id="field_description"
        label="Help Text"
        rows={2}
        placeholder="Instructions or guidelines for editors"
        hint="Shown below the field when editing content"
        value={form.data.description || ""}
        onChange={(e) => form.setData("description", e.target.value)}
      />

      <Field label="Layout Width">
        <div className="grid grid-cols-2 gap-1.5">
          <RadioTile
            name="width"
            checked={form.data.width === "full"}
            onChange={() => form.setData("width", "full")}
            className="px-3 py-2.5 text-center"
          >
            <div className="mb-2 h-1.5 rounded-full bg-base-300"></div>
            <span className="text-xs font-medium">Full width</span>
          </RadioTile>
          <RadioTile
            name="width"
            checked={form.data.width === "half"}
            onChange={() => form.setData("width", "half")}
            className="px-3 py-2.5 text-center"
          >
            <div className="mb-2 flex gap-1">
              <div className="h-1.5 flex-1 rounded-full bg-base-300"></div>
              <div className="h-1.5 flex-1 rounded-full bg-base-200"></div>
            </div>
            <span className="text-xs font-medium">Half width</span>
          </RadioTile>
        </div>
      </Field>

      <ToggleField
        label="Required field"
        description="Content cannot be saved without this field"
        checked={form.data.required}
        onChange={(checked) => form.setData("required", checked)}
      />

      {!isNew && (
        <>
          <div className="divider my-1 text-[11px] font-semibold uppercase tracking-wider text-base-content/40">
            Options
          </div>
          <FieldOptions
            fieldType={field.field_type}
            config={form.data.config}
            setConfig={(key, value) => form.setData("config", { ...form.data.config, [key]: value })}
            minItems={form.data.min_items}
            maxItems={form.data.max_items}
            setCardinality={(key, value) => form.setData(key, value)}
            referenceTargets={referenceTargets}
            embeddableComponents={embeddableComponents}
          />
        </>
      )}

      <FormActions>
        <button type="button" className="btn btn-ghost" onClick={onClose}>
          Cancel
        </button>
        <button type="submit" className="btn btn-primary" disabled={form.processing}>
          {isNew ? "Add Field" : "Save Changes"}
        </button>
      </FormActions>
    </form>
  )
}
