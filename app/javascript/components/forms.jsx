// Shared form primitives so every form in the app has identical
// label / control / hint / error rhythm.

export function Field({ label, htmlFor, hint, error, children }) {
  return (
    <div>
      <label className="mb-1.5 block text-[13px] font-medium" htmlFor={htmlFor}>
        {label}
      </label>
      {children}
      {error ? (
        <p className="mt-1.5 text-xs text-error">{Array.isArray(error) ? error.join(", ") : error}</p>
      ) : (
        hint && <p className="mt-1.5 text-xs text-base-content/50">{hint}</p>
      )}
    </div>
  )
}

export function TextInput({ label, hint, error, className = "", ...rest }) {
  return (
    <Field label={label} htmlFor={rest.id} hint={hint} error={error}>
      <input type="text" className={`input input-bordered w-full ${className}`} {...rest} />
    </Field>
  )
}

export function TextArea({ label, hint, error, className = "", ...rest }) {
  return (
    <Field label={label} htmlFor={rest.id} hint={hint} error={error}>
      <textarea className={`textarea textarea-bordered w-full leading-relaxed ${className}`} {...rest} />
    </Field>
  )
}

export function SelectInput({ label, hint, error, className = "", children, ...rest }) {
  return (
    <Field label={label} htmlFor={rest.id} hint={hint} error={error}>
      <select className={`select select-bordered w-full ${className}`} {...rest}>
        {children}
      </select>
    </Field>
  )
}

// Boolean setting as a bordered row with a toggle on the right
export function ToggleField({ label, description, checked, onChange }) {
  return (
    <label className="flex cursor-pointer items-center justify-between gap-4 rounded-field border border-base-300 bg-base-100 px-3.5 py-3 transition-colors hover:border-base-content/25">
      <span>
        <span className="block text-[13px] font-medium">{label}</span>
        {description && <span className="mt-0.5 block text-xs text-base-content/50">{description}</span>}
      </span>
      <input
        type="checkbox"
        className="toggle toggle-primary shrink-0"
        checked={checked}
        onChange={(e) => onChange(e.target.checked)}
      />
    </label>
  )
}

// Compact selectable tile for radio-style pickers
export function RadioTile({ name, checked, onChange, children, className = "" }) {
  return (
    <label className="cursor-pointer">
      <input type="radio" name={name} className="peer hidden" checked={checked} onChange={onChange} />
      <div
        className={`rounded-field border border-base-300 bg-base-100 transition-colors hover:border-base-content/25 peer-checked:border-primary peer-checked:bg-primary/5 peer-checked:ring-1 peer-checked:ring-primary ${className}`}
      >
        {children}
      </div>
    </label>
  )
}

export function FormActions({ children }) {
  return <div className="flex items-center justify-end gap-2 border-t border-base-200 pt-4">{children}</div>
}
