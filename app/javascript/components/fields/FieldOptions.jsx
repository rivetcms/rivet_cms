import { Field, TextInput, SelectInput, ToggleField, RadioTile } from "../forms"

const isTrue = (value) => value === true || value === "true"

const IMAGE_TYPES = ["jpg", "jpeg", "png", "gif", "webp", "svg"]
const VIDEO_TYPES = ["mp4", "webm", "mov", "avi"]

function OptionInput({ value, onChange, ...rest }) {
  return <TextInput value={value ?? ""} onChange={(e) => onChange(e.target.value)} {...rest} />
}

function TypeBadges({ label, allTypes, selected, onChange, hint }) {
  // nil means "all allowed" — render everything checked
  const current = selected == null ? allTypes : selected

  const toggle = (type) => {
    const next = current.includes(type) ? current.filter((t) => t !== type) : [...current, type]
    onChange(next)
  }

  return (
    <Field label={label} hint={hint}>
      <div className="flex flex-wrap gap-1.5">
        {allTypes.map((type) => (
          <label key={type} className="cursor-pointer">
            <input type="checkbox" className="peer hidden" checked={current.includes(type)} onChange={() => toggle(type)} />
            <span className="badge badge-ghost border-base-300 font-mono text-xs transition-colors peer-checked:badge-primary">
              .{type}
            </span>
          </label>
        ))}
      </div>
    </Field>
  )
}

export default function FieldOptions({ fieldType, options, setOption, referenceTargets, embeddableComponents }) {
  switch (fieldType) {
    case "string":
      return (
        <div className="space-y-4">
          <OptionInput label="Maximum Length" type="number" min={1} placeholder="No limit" hint="Leave empty for no limit" value={options.max_length} onChange={(v) => setOption("max_length", v)} />
          <OptionInput label="Placeholder Text" placeholder="e.g., Enter a title..." value={options.placeholder} onChange={(v) => setOption("placeholder", v)} />
        </div>
      )
    case "text":
      return (
        <div className="space-y-4">
          <OptionInput label="Maximum Length" type="number" min={1} placeholder="No limit" hint="Leave empty for no limit" value={options.max_length} onChange={(v) => setOption("max_length", v)} />
          <OptionInput label="Placeholder Text" placeholder="e.g., Write your content here..." value={options.placeholder} onChange={(v) => setOption("placeholder", v)} />
          <OptionInput label="Default Rows" type="number" min={2} max={20} hint="Height of the text area (2-20 rows)" value={options.rows ?? 4} onChange={(v) => setOption("rows", v)} />
        </div>
      )
    case "rich_text":
      return (
        <Field label="Toolbar Style">
          <div className="grid grid-cols-3 gap-1.5">
            {[
              ["minimal", "Minimal", "Bold, italic, links only"],
              ["standard", "Standard", "Common formatting options"],
              ["full", "Full", "All formatting features"],
            ].map(([value, label, desc]) => (
              <RadioTile
                key={value}
                name="toolbar"
                checked={(options.toolbar || "standard") === value}
                onChange={() => setOption("toolbar", value)}
                className="px-2 py-2.5 text-center"
              >
                <span className="block text-[13px] font-medium">{label}</span>
                <span className="mt-0.5 block text-[11px] leading-tight text-base-content/50">{desc}</span>
              </RadioTile>
            ))}
          </div>
        </Field>
      )
    case "markdown":
      return (
        <div className="space-y-4">
          <ToggleField label="Enable Live Preview" description="Show rendered markdown alongside the editor" checked={isTrue(options.preview)} onChange={(v) => setOption("preview", v)} />
          <OptionInput label="Placeholder Text" placeholder="e.g., Write in markdown..." value={options.placeholder} onChange={(v) => setOption("placeholder", v)} />
        </div>
      )
    case "integer":
      return (
        <div className="space-y-4">
          <div className="grid grid-cols-2 gap-3">
            <OptionInput label="Minimum Value" type="number" placeholder="No minimum" value={options.min} onChange={(v) => setOption("min", v)} />
            <OptionInput label="Maximum Value" type="number" placeholder="No maximum" value={options.max} onChange={(v) => setOption("max", v)} />
          </div>
          <OptionInput label="Step Increment" type="number" min={1} hint="Increment when using arrows (default: 1)" value={options.step ?? 1} onChange={(v) => setOption("step", v)} />
          <OptionInput label="Default Value" type="number" placeholder="No default" value={options.default} onChange={(v) => setOption("default", v)} />
        </div>
      )
    case "boolean":
      return (
        <Field label="Default Value" hint="Initial value when creating new content">
          <div className="grid grid-cols-2 gap-1.5">
            <RadioTile name="default" checked={!isTrue(options.default)} onChange={() => setOption("default", "false")} className="px-3 py-2 text-center">
              <span className="text-[13px] font-medium">False (Off)</span>
            </RadioTile>
            <RadioTile name="default" checked={isTrue(options.default)} onChange={() => setOption("default", "true")} className="px-3 py-2 text-center">
              <span className="text-[13px] font-medium">True (On)</span>
            </RadioTile>
          </div>
        </Field>
      )
    case "image":
      return (
        <div className="space-y-4">
          <OptionInput label="Maximum File Size (MB)" type="number" min={1} max={100} hint="Default: 10 MB" value={options.max_size_mb ?? 10} onChange={(v) => setOption("max_size_mb", v)} />
          <TypeBadges label="Allowed Image Types" allTypes={IMAGE_TYPES} selected={options.allowed_types} onChange={(v) => setOption("allowed_types", v)} hint="Select allowed image formats" />
          <ToggleField label="Require Alt Text" description="Force editors to provide alt text for accessibility" checked={isTrue(options.alt_required)} onChange={(v) => setOption("alt_required", v)} />
        </div>
      )
    case "video":
      return (
        <div className="space-y-4">
          <OptionInput label="Maximum File Size (MB)" type="number" min={1} max={1000} hint="Default: 100 MB" value={options.max_size_mb ?? 100} onChange={(v) => setOption("max_size_mb", v)} />
          <TypeBadges label="Allowed Video Types" allTypes={VIDEO_TYPES} selected={options.allowed_types} onChange={(v) => setOption("allowed_types", v)} hint="Select allowed video formats" />
        </div>
      )
    case "file":
      return (
        <div className="space-y-4">
          <OptionInput label="Maximum File Size (MB)" type="number" min={1} max={500} hint="Default: 50 MB" value={options.max_size_mb ?? 50} onChange={(v) => setOption("max_size_mb", v)} />
          <OptionInput
            label="Allowed File Extensions"
            placeholder="e.g., pdf, doc, docx, xls, xlsx"
            hint="Comma-separated list of extensions (leave empty to allow all)"
            value={Array.isArray(options.allowed_types) ? options.allowed_types.join(", ") : options.allowed_types}
            onChange={(v) => setOption("allowed_types", v)}
          />
        </div>
      )
    case "reference":
      return (
        <div className="space-y-4">
          <SelectInput
            label="Reference Content Type"
            hint="Which content type can be referenced"
            value={options.content_type_id ?? ""}
            onChange={(e) => setOption("content_type_id", e.target.value)}
          >
            <option value="">Select a content type...</option>
            {referenceTargets.map((ct) => (
              <option key={ct.id} value={ct.id}>{ct.name}</option>
            ))}
          </SelectInput>
          <ToggleField label="Allow Multiple References" description="Allow selecting more than one item" checked={isTrue(options.multiple)} onChange={(v) => setOption("multiple", v)} />
        </div>
      )
    case "component":
      return (
        <div className="space-y-4">
          <SelectInput
            label="Embed Component"
            hint="Which component to embed in this field"
            value={options.component_id ?? ""}
            onChange={(e) => setOption("component_id", e.target.value)}
          >
            <option value="">Select a component...</option>
            {embeddableComponents.map((c) => (
              <option key={c.id} value={c.id}>{c.name}</option>
            ))}
          </SelectInput>
          <ToggleField label="Allow Repeating" description="Allow adding multiple instances of this component" checked={isTrue(options.repeatable)} onChange={(v) => setOption("repeatable", v)} />
          {isTrue(options.repeatable) && (
            <div className="grid grid-cols-2 gap-3">
              <OptionInput label="Minimum Items" type="number" min={0} placeholder="0" value={options.min_items} onChange={(v) => setOption("min_items", v)} />
              <OptionInput label="Maximum Items" type="number" min={1} placeholder="Unlimited" value={options.max_items} onChange={(v) => setOption("max_items", v)} />
            </div>
          )}
        </div>
      )
    default:
      return null
  }
}
