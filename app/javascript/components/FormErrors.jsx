// Renders a field's server-side validation messages under an input
export function FieldError({ error }) {
  if (!error) return null
  const messages = Array.isArray(error) ? error : [error]

  return (
    <label className="label">
      <span className="label-text-alt text-error">{messages.join(", ")}</span>
    </label>
  )
}
