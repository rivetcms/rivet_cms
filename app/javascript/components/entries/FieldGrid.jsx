import EntryField from "./EntryField"

// Renders fields respecting the schema layout: half-width fields share a
// two-column row, full-width fields span it.
export default function FieldGrid({ fields, values, setValue, referenceOptions, errors = {} }) {
  const rows = []
  for (const field of fields) {
    const last = rows[rows.length - 1]
    if (last && last[0].row === field.row) last.push(field)
    else rows.push([field])
  }

  return rows.map((rowFields) => (
    <div key={rowFields[0].key} className="grid grid-cols-1 gap-5 sm:grid-cols-2">
      {rowFields.map((field) => (
        <div key={field.key} className={field.width === "half" ? "" : "sm:col-span-2"}>
          <EntryField
            field={field}
            value={values[field.key]}
            onChange={(value) => setValue(field.key, value)}
            referenceOptions={referenceOptions}
            error={errors[field.key]}
          />
        </div>
      ))}
    </div>
  ))
}
