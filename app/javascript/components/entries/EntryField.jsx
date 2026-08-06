import { useState } from "react"
import { Field, TextInput, TextArea, SelectInput } from "../forms"
import RichTextEditor from "./RichTextEditor"
import MarkdownEditor from "./MarkdownEditor"
import MediaPicker from "./MediaPicker"
import Thumbnail from "../Thumbnail"
import FieldGrid from "./FieldGrid"

function ComponentField({ field, value, onChange, referenceOptions, error }) {
  const schema = field.component
  const instances = Array.isArray(value) ? value : []

  if (!schema) {
    return <Field label={field.label} hint="Choose a component for this field in the schema builder first." />
  }

  const canAdd = field.max_items == null || instances.length < field.max_items
  const add = () => onChange([...instances, { values: {} }])
  const remove = (index) => onChange(instances.filter((_, i) => i !== index))
  const move = (index, delta) => {
    const next = [...instances]
    const [moved] = next.splice(index, 1)
    next.splice(index + delta, 0, moved)
    onChange(next)
  }
  const setInstanceValue = (index, key, v) => {
    onChange(instances.map((instance, i) => (
      i === index ? { ...instance, values: { ...instance.values, [key]: v } } : instance
    )))
  }

  return (
    <Field label={field.label} hint={field.description} error={error}>
      <div className="space-y-3">
        {instances.map((instance, index) => (
          <div key={index} className="rounded-field border border-base-300 bg-base-200/30">
            <div className="flex items-center justify-between border-b border-base-300 px-3 py-1.5">
              <span className="text-[11px] font-semibold uppercase tracking-wider text-base-content/50">
                {schema.name}{instances.length > 1 ? ` ${index + 1}` : ""}
              </span>
              <div className="flex items-center gap-1">
                {instances.length > 1 && (
                  <>
                    <button type="button" onClick={() => move(index, -1)} disabled={index === 0} className="text-base-content/40 transition-colors hover:text-base-content disabled:opacity-25 disabled:hover:text-base-content/40" aria-label="Move up">
                      <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m18 15-6-6-6 6"/></svg>
                    </button>
                    <button type="button" onClick={() => move(index, 1)} disabled={index === instances.length - 1} className="text-base-content/40 transition-colors hover:text-base-content disabled:opacity-25 disabled:hover:text-base-content/40" aria-label="Move down">
                      <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m6 9 6 6 6-6"/></svg>
                    </button>
                    <span className="mx-0.5 h-3.5 w-px bg-base-300" />
                  </>
                )}
                <button type="button" onClick={() => remove(index)} className="text-base-content/40 transition-colors hover:text-error" aria-label={`Remove ${schema.name}`}>
                  <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
                </button>
              </div>
            </div>
            <div className="space-y-4 p-3">
              <FieldGrid
                fields={schema.fields}
                values={instance.values || {}}
                setValue={(key, v) => setInstanceValue(index, key, v)}
                referenceOptions={referenceOptions}
              />
            </div>
          </div>
        ))}
        {canAdd && (
          <button type="button" onClick={add} className="btn btn-ghost btn-sm w-full border border-dashed border-base-300">
            + Add {schema.name}
          </button>
        )}
      </div>
    </Field>
  )
}

function ReferenceInput({ field, value, onChange, options, error }) {
  const selected = Array.isArray(value) ? value.map(Number) : value == null ? [] : [Number(value)]
  const single = field.max_items === 1

  if (single) {
    return (
      <SelectInput
        label={field.label}
        hint={field.description}
        error={error}
        value={selected[0] ?? ""}
        onChange={(e) => onChange(e.target.value ? [Number(e.target.value)] : [])}
      >
        <option value="">None</option>
        {options.map((o) => (
          <option key={o.id} value={o.id}>{o.slug} ({o.content_type})</option>
        ))}
      </SelectInput>
    )
  }

  const toggle = (id) => {
    const set = new Set(selected)
    set.has(id) ? set.delete(id) : set.add(id)
    onChange([...set])
  }

  return (
    <Field label={field.label} hint={field.description} error={error}>
      <div className="max-h-48 space-y-1 overflow-y-auto rounded-field border border-base-300 p-2">
        {options.length === 0 && <p className="text-[13px] text-base-content/50">No documents available to reference.</p>}
        {options.map((o) => (
          <label key={o.id} className="flex cursor-pointer items-center gap-2 text-[13px]">
            <input type="checkbox" className="checkbox checkbox-sm" checked={selected.includes(o.id)} onChange={() => toggle(o.id)} />
            <span>{o.slug} <span className="text-base-content/50">({o.content_type})</span></span>
          </label>
        ))}
      </div>
    </Field>
  )
}

function MediaField({ field, value, onChange, error }) {
  const [open, setOpen] = useState(false)
  const kind = field.field_type === "image" ? "image" : field.field_type === "video" ? "video" : null

  return (
    <Field label={field.label} hint={field.description} error={error}>
      <div className="flex items-center gap-3">
        {value ? (
          <div className="flex items-center gap-2 rounded-field border border-base-300 py-1.5 pl-1.5 pr-3">
            {value.kind === "image" && value.url ? (
              <Thumbnail src={value.thumbnail_url || value.url} alt={value.alt || value.filename} className="size-9 rounded-selector object-cover" />
            ) : (
              <span className="flex size-9 items-center justify-center rounded-selector bg-base-200 text-base-content/40">
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"><path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/><path d="M14 2v4a2 2 0 0 0 2 2h4"/></svg>
              </span>
            )}
            <span className="max-w-48 truncate text-[13px]">{value.filename}</span>
            <button type="button" onClick={() => onChange(null)} className="text-base-content/40 transition-colors hover:text-error" aria-label="Remove">
              <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
            </button>
          </div>
        ) : (
          <span className="text-[13px] text-base-content/50">Nothing selected</span>
        )}
        <button type="button" className="btn btn-ghost btn-sm border border-base-300" onClick={() => setOpen(true)}>
          {value ? "Change" : "Choose"}
        </button>
      </div>
      <MediaPicker open={open} onClose={() => setOpen(false)} onSelect={onChange} kind={kind} />
    </Field>
  )
}

export default function EntryField({ field, value, onChange, referenceOptions, error }) {
  const config = field.config || {}
  const common = { label: field.label, hint: field.description, required: field.required, placeholder: config.placeholder, error }
  const numeric = { min: config.min, max: config.max, step: config.step }

  switch (field.field_type) {
    case "string":
      // Native pattern gives save-time feedback consistent with required;
      // publish-time server validation stays authoritative (a pattern the
      // browser's regex dialect can't parse is simply ignored here).
      return (
        <TextInput
          {...common}
          pattern={config.pattern || undefined}
          title={config.pattern ? field.description || "Must match the required format" : undefined}
          value={value ?? ""}
          onChange={(e) => onChange(e.target.value)}
        />
      )
    case "text":
      return <TextArea {...common} rows={config.rows || 4} value={value ?? ""} onChange={(e) => onChange(e.target.value)} />
    case "rich_text":
      return (
        <Field label={field.label} hint={field.description} error={error}>
          <RichTextEditor value={value} onChange={onChange} />
        </Field>
      )
    case "markdown":
      return (
        <Field label={field.label} hint={field.description} error={error}>
          <MarkdownEditor value={value} onChange={onChange} />
        </Field>
      )
    case "integer":
      return <TextInput {...common} {...numeric} type="number" value={value ?? ""} onChange={(e) => onChange(e.target.value === "" ? null : Number(e.target.value))} />
    case "decimal":
      // Sent as the raw string so the server casts to an exact decimal.
      return <TextInput {...common} {...numeric} type="number" step={config.step || "any"} value={value ?? ""} onChange={(e) => onChange(e.target.value || null)} />
    case "enumeration":
      return (
        <SelectInput {...common} value={value ?? ""} onChange={(e) => onChange(e.target.value || null)}>
          <option value="">Select...</option>
          {(config.choices || []).map((choice) => (
            <option key={choice} value={choice}>{choice}</option>
          ))}
        </SelectInput>
      )
    case "date":
      return <TextInput {...common} type="date" value={(value ?? "").slice(0, 10)} onChange={(e) => onChange(e.target.value || null)} />
    case "datetime":
      return <TextInput {...common} type="datetime-local" value={(value ?? "").slice(0, 16)} onChange={(e) => onChange(e.target.value || null)} />
    case "boolean":
      return (
        <Field label={field.label} hint={field.description} error={error}>
          <label className="flex h-[calc(var(--size-field)*10)] w-full cursor-pointer items-center justify-between rounded-field border border-base-300 bg-base-100 px-3 transition-colors focus-within:border-primary">
            <span className="text-[13px] text-base-content/60">{value ? "Yes" : "No"}</span>
            <input type="checkbox" className="toggle toggle-primary toggle-sm" checked={!!value} onChange={(e) => onChange(e.target.checked)} />
          </label>
        </Field>
      )
    case "reference":
      return <ReferenceInput field={field} value={value} onChange={onChange} options={referenceOptions} error={error} />
    case "image":
    case "video":
    case "file":
      return <MediaField field={field} value={value} onChange={onChange} error={error} />
    case "component":
      return <ComponentField field={field} value={value} onChange={onChange} referenceOptions={referenceOptions} error={error} />
    default:
      return null
  }
}
