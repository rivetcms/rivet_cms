const isTrue = (value) => value === true || value === "true"

const IMAGE_TYPES = ["jpg", "jpeg", "png", "gif", "webp", "svg"]
const VIDEO_TYPES = ["mp4", "webm", "mov", "avi"]

function TextInput({ label, value, onChange, hint, placeholder, type = "text", ...rest }) {
  return (
    <div className="form-control">
      <label className="label">{label}</label>
      <input
        type={type}
        className="input input-bordered w-full"
        value={value ?? ""}
        placeholder={placeholder}
        onChange={(e) => onChange(e.target.value)}
        {...rest}
      />
      {hint && (
        <label className="label">
          <span className="label-text-alt text-base-content/50">{hint}</span>
        </label>
      )}
    </div>
  )
}

function CheckboxCard({ label, description, checked, onChange }) {
  return (
    <div className="form-control">
      <label className="label cursor-pointer justify-start gap-4 p-4 bg-base-200/50 rounded-lg hover:bg-base-200 transition-colors">
        <input
          type="checkbox"
          className="checkbox checkbox-primary"
          checked={checked}
          onChange={(e) => onChange(e.target.checked)}
        />
        <div>
          <span className="font-medium">{label}</span>
          <p className="text-base-content/50 text-sm mt-0.5">{description}</p>
        </div>
      </label>
    </div>
  )
}

function TypeBadges({ label, allTypes, selected, onChange, hint }) {
  // nil means "all allowed" — render everything checked
  const current = selected == null ? allTypes : selected

  const toggle = (type) => {
    const next = current.includes(type) ? current.filter((t) => t !== type) : [...current, type]
    onChange(next)
  }

  return (
    <div className="form-control">
      <label className="label">{label}</label>
      <div className="flex flex-wrap gap-2">
        {allTypes.map((type) => (
          <label key={type} className="cursor-pointer">
            <input type="checkbox" className="peer hidden" checked={current.includes(type)} onChange={() => toggle(type)} />
            <span className="badge badge-lg peer-checked:badge-primary peer-checked:text-primary-content transition-colors cursor-pointer">
              .{type}
            </span>
          </label>
        ))}
      </div>
      <label className="label">
        <span className="label-text-alt text-base-content/50">{hint}</span>
      </label>
    </div>
  )
}

export default function FieldOptions({ fieldType, options, setOption, referenceTargets, embeddableComponents }) {
  switch (fieldType) {
    case "string":
      return (
        <div className="space-y-4">
          <TextInput label="Maximum Length" type="number" min={1} placeholder="No limit" hint="Leave empty for no limit" value={options.max_length} onChange={(v) => setOption("max_length", v)} />
          <TextInput label="Placeholder Text" placeholder="e.g., Enter a title..." value={options.placeholder} onChange={(v) => setOption("placeholder", v)} />
        </div>
      )
    case "text":
      return (
        <div className="space-y-4">
          <TextInput label="Maximum Length" type="number" min={1} placeholder="No limit" hint="Leave empty for no limit" value={options.max_length} onChange={(v) => setOption("max_length", v)} />
          <TextInput label="Placeholder Text" placeholder="e.g., Write your content here..." value={options.placeholder} onChange={(v) => setOption("placeholder", v)} />
          <TextInput label="Default Rows" type="number" min={2} max={20} hint="Height of the text area (2-20 rows)" value={options.rows ?? 4} onChange={(v) => setOption("rows", v)} />
        </div>
      )
    case "rich_text":
      return (
        <div className="space-y-4">
          <div className="form-control">
            <label className="label">Toolbar Style</label>
            <div className="grid grid-cols-3 gap-2">
              {[
                ["minimal", "Minimal", "Bold, italic, links only"],
                ["standard", "Standard", "Common formatting options"],
                ["full", "Full", "All formatting features"],
              ].map(([value, label, desc]) => (
                <label key={value} className="cursor-pointer">
                  <input
                    type="radio"
                    className="peer hidden"
                    checked={(options.toolbar || "standard") === value}
                    onChange={() => setOption("toolbar", value)}
                  />
                  <div className="border-2 border-base-300 rounded-lg p-3 text-center transition-all peer-checked:border-primary peer-checked:bg-primary/5">
                    <span className="text-sm font-medium block">{label}</span>
                    <span className="text-xs text-base-content/50">{desc}</span>
                  </div>
                </label>
              ))}
            </div>
          </div>
        </div>
      )
    case "markdown":
      return (
        <div className="space-y-4">
          <CheckboxCard label="Enable Live Preview" description="Show rendered markdown alongside the editor" checked={isTrue(options.preview)} onChange={(v) => setOption("preview", v)} />
          <TextInput label="Placeholder Text" placeholder="e.g., Write in markdown..." value={options.placeholder} onChange={(v) => setOption("placeholder", v)} />
        </div>
      )
    case "integer":
      return (
        <div className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <TextInput label="Minimum Value" type="number" placeholder="No minimum" value={options.min} onChange={(v) => setOption("min", v)} />
            <TextInput label="Maximum Value" type="number" placeholder="No maximum" value={options.max} onChange={(v) => setOption("max", v)} />
          </div>
          <TextInput label="Step Increment" type="number" min={1} hint="Increment when using arrows (default: 1)" value={options.step ?? 1} onChange={(v) => setOption("step", v)} />
          <TextInput label="Default Value" type="number" placeholder="No default" value={options.default} onChange={(v) => setOption("default", v)} />
        </div>
      )
    case "boolean":
      return (
        <div className="space-y-4">
          <div className="form-control">
            <label className="label">Default Value</label>
            <div className="flex gap-4">
              <label className="flex items-center gap-2 cursor-pointer">
                <input type="radio" className="radio radio-primary" checked={!isTrue(options.default)} onChange={() => setOption("default", "false")} />
                <span>False (Off)</span>
              </label>
              <label className="flex items-center gap-2 cursor-pointer">
                <input type="radio" className="radio radio-primary" checked={isTrue(options.default)} onChange={() => setOption("default", "true")} />
                <span>True (On)</span>
              </label>
            </div>
            <label className="label">
              <span className="label-text-alt text-base-content/50">Initial value when creating new content</span>
            </label>
          </div>
        </div>
      )
    case "image":
      return (
        <div className="space-y-4">
          <TextInput label="Maximum File Size (MB)" type="number" min={1} max={100} hint="Default: 10 MB" value={options.max_size_mb ?? 10} onChange={(v) => setOption("max_size_mb", v)} />
          <TypeBadges label="Allowed Image Types" allTypes={IMAGE_TYPES} selected={options.allowed_types} onChange={(v) => setOption("allowed_types", v)} hint="Select allowed image formats" />
          <CheckboxCard label="Require Alt Text" description="Force editors to provide alt text for accessibility" checked={isTrue(options.alt_required)} onChange={(v) => setOption("alt_required", v)} />
        </div>
      )
    case "video":
      return (
        <div className="space-y-4">
          <TextInput label="Maximum File Size (MB)" type="number" min={1} max={1000} hint="Default: 100 MB" value={options.max_size_mb ?? 100} onChange={(v) => setOption("max_size_mb", v)} />
          <TypeBadges label="Allowed Video Types" allTypes={VIDEO_TYPES} selected={options.allowed_types} onChange={(v) => setOption("allowed_types", v)} hint="Select allowed video formats" />
        </div>
      )
    case "file":
      return (
        <div className="space-y-4">
          <TextInput label="Maximum File Size (MB)" type="number" min={1} max={500} hint="Default: 50 MB" value={options.max_size_mb ?? 50} onChange={(v) => setOption("max_size_mb", v)} />
          <TextInput
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
          <div className="form-control">
            <label className="label">Reference Content Type</label>
            <select
              className="select select-bordered w-full"
              value={options.content_type_id ?? ""}
              onChange={(e) => setOption("content_type_id", e.target.value)}
            >
              <option value="">Select a content type...</option>
              {referenceTargets.map((ct) => (
                <option key={ct.id} value={ct.id}>{ct.name}</option>
              ))}
            </select>
            <label className="label">
              <span className="label-text-alt text-base-content/50">Which content type can be referenced</span>
            </label>
          </div>
          <CheckboxCard label="Allow Multiple References" description="Allow selecting more than one item" checked={isTrue(options.multiple)} onChange={(v) => setOption("multiple", v)} />
        </div>
      )
    case "component":
      return (
        <div className="space-y-4">
          <div className="form-control">
            <label className="label">Embed Component</label>
            <select
              className="select select-bordered w-full"
              value={options.component_id ?? ""}
              onChange={(e) => setOption("component_id", e.target.value)}
            >
              <option value="">Select a component...</option>
              {embeddableComponents.map((c) => (
                <option key={c.id} value={c.id}>{c.name}</option>
              ))}
            </select>
            <label className="label">
              <span className="label-text-alt text-base-content/50">Which component to embed in this field</span>
            </label>
          </div>
          <CheckboxCard label="Allow Repeating" description="Allow adding multiple instances of this component" checked={isTrue(options.repeatable)} onChange={(v) => setOption("repeatable", v)} />
          {isTrue(options.repeatable) && (
            <div className="grid grid-cols-2 gap-4">
              <TextInput label="Minimum Items" type="number" min={0} placeholder="0" value={options.min_items} onChange={(v) => setOption("min_items", v)} />
              <TextInput label="Maximum Items" type="number" min={1} placeholder="Unlimited" value={options.max_items} onChange={(v) => setOption("max_items", v)} />
            </div>
          )}
        </div>
      )
    default:
      return null
  }
}
