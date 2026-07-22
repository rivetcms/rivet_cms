import { useState } from "react"
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

// Raw text is local state so typing a newline isn't swallowed by the
// join/split round-trip; config gets the cleaned array.
function ChoicesInput({ config, setConfig }) {
  const [raw, setRaw] = useState((config.choices || []).join("\n"))

  const update = (text) => {
    setRaw(text)
    setConfig("choices", text.split("\n").map((line) => line.trim()).filter(Boolean))
  }

  return (
    <Field label="Choices" hint="One choice per line; editors pick from these values">
      <textarea
        className="textarea w-full font-mono text-[13px]"
        rows={5}
        placeholder={"draft\nreview\nlive"}
        value={raw}
        onChange={(e) => update(e.target.value)}
      />
    </Field>
  )
}

const PATTERN_PRESETS = [
  ["Email", "^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$"],
  ["URL", "^https?://\\S+$"],
]

function PatternInput({ config, setConfig }) {
  return (
    <div>
      <OptionInput
        label="Pattern (regex)"
        placeholder="e.g., ^[A-Z]{2}-\d{4}$"
        hint="Values must match this regular expression to publish"
        value={config.pattern}
        onChange={(v) => setConfig("pattern", v)}
      />
      <div className="mt-1.5 flex items-center gap-1.5">
        <span className="text-[11px] text-base-content/40">Presets:</span>
        {PATTERN_PRESETS.map(([label, pattern]) => (
          <button
            key={label}
            type="button"
            className={`badge cursor-pointer border-base-300 text-xs transition-colors ${config.pattern === pattern ? "badge-primary" : "badge-ghost"}`}
            onClick={() => setConfig("pattern", pattern)}
          >
            {label}
          </button>
        ))}
      </div>
    </div>
  )
}

export default function FieldOptions({ fieldType, config, setConfig, minItems, maxItems, setCardinality, referenceTargets, embeddableComponents }) {
  const toNumberOrNull = (v) => (v === "" || v == null ? null : Number(v))
  const multiple = maxItems !== 1

  switch (fieldType) {
    case "string":
      return (
        <div className="space-y-4">
          <OptionInput label="Maximum Length" type="number" min={1} placeholder="No limit" hint="Leave empty for no limit" value={config.max_length} onChange={(v) => setConfig("max_length", v)} />
          <OptionInput label="Placeholder Text" placeholder="e.g., Enter a title..." value={config.placeholder} onChange={(v) => setConfig("placeholder", v)} />
          <PatternInput config={config} setConfig={setConfig} />
        </div>
      )
    case "text":
      return (
        <div className="space-y-4">
          <OptionInput label="Maximum Length" type="number" min={1} placeholder="No limit" hint="Leave empty for no limit" value={config.max_length} onChange={(v) => setConfig("max_length", v)} />
          <OptionInput label="Placeholder Text" placeholder="e.g., Write your content here..." value={config.placeholder} onChange={(v) => setConfig("placeholder", v)} />
          <OptionInput label="Default Rows" type="number" min={2} max={20} hint="Height of the text area (2-20 rows)" value={config.rows ?? 4} onChange={(v) => setConfig("rows", v)} />
          <PatternInput config={config} setConfig={setConfig} />
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
                checked={(config.toolbar || "standard") === value}
                onChange={() => setConfig("toolbar", value)}
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
          <ToggleField label="Enable Live Preview" description="Show rendered markdown alongside the editor" checked={isTrue(config.preview)} onChange={(v) => setConfig("preview", v)} />
          <OptionInput label="Placeholder Text" placeholder="e.g., Write in markdown..." value={config.placeholder} onChange={(v) => setConfig("placeholder", v)} />
        </div>
      )
    case "integer":
      return (
        <div className="space-y-4">
          <div className="grid grid-cols-2 gap-3">
            <OptionInput label="Minimum Value" type="number" placeholder="No minimum" value={config.min} onChange={(v) => setConfig("min", v)} />
            <OptionInput label="Maximum Value" type="number" placeholder="No maximum" value={config.max} onChange={(v) => setConfig("max", v)} />
          </div>
          <OptionInput label="Step Increment" type="number" min={1} hint="Increment when using arrows (default: 1)" value={config.step ?? 1} onChange={(v) => setConfig("step", v)} />
          <OptionInput label="Default Value" type="number" placeholder="No default" value={config.default} onChange={(v) => setConfig("default", v)} />
        </div>
      )
    case "decimal":
      return (
        <div className="space-y-4">
          <div className="grid grid-cols-2 gap-3">
            <OptionInput label="Minimum Value" type="number" placeholder="No minimum" value={config.min} onChange={(v) => setConfig("min", v)} />
            <OptionInput label="Maximum Value" type="number" placeholder="No maximum" value={config.max} onChange={(v) => setConfig("max", v)} />
          </div>
          <OptionInput label="Step Increment" type="number" hint="Increment when using arrows (default: any)" value={config.step} onChange={(v) => setConfig("step", v)} />
          <OptionInput label="Placeholder Text" placeholder="e.g., 19.99" value={config.placeholder} onChange={(v) => setConfig("placeholder", v)} />
        </div>
      )
    case "enumeration":
      return <ChoicesInput config={config} setConfig={setConfig} />
    case "boolean":
      return (
        <Field label="Default Value" hint="Initial value when creating new content">
          <div className="grid grid-cols-2 gap-1.5">
            <RadioTile name="default" checked={!isTrue(config.default)} onChange={() => setConfig("default", "false")} className="px-3 py-2 text-center">
              <span className="text-[13px] font-medium">False (Off)</span>
            </RadioTile>
            <RadioTile name="default" checked={isTrue(config.default)} onChange={() => setConfig("default", "true")} className="px-3 py-2 text-center">
              <span className="text-[13px] font-medium">True (On)</span>
            </RadioTile>
          </div>
        </Field>
      )
    case "image":
      return (
        <div className="space-y-4">
          <OptionInput label="Maximum File Size (MB)" type="number" min={1} max={100} hint="Default: 10 MB" value={config.max_size_mb ?? 10} onChange={(v) => setConfig("max_size_mb", v)} />
          <TypeBadges label="Allowed Image Types" allTypes={IMAGE_TYPES} selected={config.allowed_types} onChange={(v) => setConfig("allowed_types", v)} hint="Select allowed image formats" />
          <ToggleField label="Require Alt Text" description="Force editors to provide alt text for accessibility" checked={isTrue(config.alt_required)} onChange={(v) => setConfig("alt_required", v)} />
        </div>
      )
    case "video":
      return (
        <div className="space-y-4">
          <OptionInput label="Maximum File Size (MB)" type="number" min={1} max={1000} hint="Default: 100 MB" value={config.max_size_mb ?? 100} onChange={(v) => setConfig("max_size_mb", v)} />
          <TypeBadges label="Allowed Video Types" allTypes={VIDEO_TYPES} selected={config.allowed_types} onChange={(v) => setConfig("allowed_types", v)} hint="Select allowed video formats" />
        </div>
      )
    case "file":
      return (
        <div className="space-y-4">
          <OptionInput label="Maximum File Size (MB)" type="number" min={1} max={500} hint="Default: 50 MB" value={config.max_size_mb ?? 50} onChange={(v) => setConfig("max_size_mb", v)} />
          <OptionInput
            label="Allowed File Extensions"
            placeholder="e.g., pdf, doc, docx, xls, xlsx"
            hint="Comma-separated list of extensions (leave empty to allow all)"
            value={Array.isArray(config.allowed_types) ? config.allowed_types.join(", ") : config.allowed_types}
            onChange={(v) => setConfig("allowed_types", v)}
          />
        </div>
      )
    case "reference":
      return (
        <div className="space-y-4">
          <SelectInput
            label="Reference Content Type"
            hint="Which content type can be referenced"
            value={config.content_type_id ?? ""}
            onChange={(e) => setConfig("content_type_id", e.target.value)}
          >
            <option value="">Select a content type...</option>
            {referenceTargets.map((ct) => (
              <option key={ct.id} value={ct.id}>{ct.name}</option>
            ))}
          </SelectInput>
          <ToggleField label="Allow Multiple References" description="Allow selecting more than one item" checked={multiple} onChange={(v) => setCardinality("max_items", v ? null : 1)} />
        </div>
      )
    case "component":
      return (
        <div className="space-y-4">
          <SelectInput
            label="Embed Component"
            hint="Which component to embed in this field"
            value={config.component_id ?? ""}
            onChange={(e) => setConfig("component_id", e.target.value)}
          >
            <option value="">Select a component...</option>
            {embeddableComponents.map((c) => (
              <option key={c.id} value={c.id}>{c.name}</option>
            ))}
          </SelectInput>
          <ToggleField label="Allow Repeating" description="Allow adding multiple instances of this component" checked={multiple} onChange={(v) => setCardinality("max_items", v ? null : 1)} />
          {multiple && (
            <div className="grid grid-cols-2 gap-3">
              <OptionInput label="Minimum Items" type="number" min={0} placeholder="0" value={minItems} onChange={(v) => setCardinality("min_items", toNumberOrNull(v))} />
              <OptionInput label="Maximum Items" type="number" min={1} placeholder="Unlimited" value={maxItems} onChange={(v) => setCardinality("max_items", toNumberOrNull(v))} />
            </div>
          )}
        </div>
      )
    default:
      return null
  }
}
