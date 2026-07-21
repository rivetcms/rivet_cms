import { useState } from "react"
import { Link, usePage } from "@inertiajs/react"
import FieldsBuilder from "../../components/fields/FieldsBuilder"
import FieldDrawer from "../../components/fields/FieldDrawer"

function AddFieldButton({ onClick, children }) {
  return (
    <button type="button" className="btn btn-primary btn-sm gap-2" onClick={onClick}>
      <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M5 12h14"/><path d="M12 5v14"/></svg>
      {children}
    </button>
  )
}

export default function Show({
  content_type: contentType,
  fields,
  field_types: fieldTypes,
  reference_targets: referenceTargets,
  embeddable_components: embeddableComponents,
}) {
  const { paths } = usePage().props
  // null = closed, { field: null } = new field, { field } = edit field
  const [drawer, setDrawer] = useState(null)

  const openNew = () => setDrawer({ field: null })
  const openEdit = (field) => setDrawer({ field })
  const close = () => setDrawer(null)

  return (
    <>
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8">
        <div className="space-y-1">
          <div className="flex items-center gap-3">
            <h1 className="text-2xl font-bold tracking-tight">{contentType.name}</h1>
            <span className={`badge ${contentType.single ? "badge-warning" : "badge-info"} badge-sm font-medium`}>
              {contentType.single ? "Single" : "Collection"}
            </span>
          </div>
          <div className="flex items-center gap-2 text-base-content/50 text-sm">
            <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>
            <code className="text-xs bg-base-200 px-2 py-0.5 rounded font-mono">{contentType.slug}</code>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <Link href={contentType.paths.edit} className="btn btn-outline btn-sm gap-2">
            <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 20h9"/><path d="M16.376 3.622a1 1 0 0 1 3.002 3.002L7.368 18.635a2 2 0 0 1-.855.506l-2.872.838a.5.5 0 0 1-.62-.62l.838-2.872a2 2 0 0 1 .506-.854z"/></svg>
            Settings
          </Link>
          <AddFieldButton onClick={openNew}>Add Field</AddFieldButton>
        </div>
      </div>

      <div className="bg-base-100 border border-base-300 rounded-xl">
        <div className="p-5 border-b border-base-200">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-lg bg-primary/10 flex items-center justify-center">
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-primary"><rect width="8" height="4" x="8" y="2" rx="1" ry="1"/><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"/><path d="M12 11h4"/><path d="M12 16h4"/><path d="M8 11h.01"/><path d="M8 16h.01"/></svg>
              </div>
              <div>
                <h2 className="font-semibold">Fields</h2>
                <p className="text-xs text-base-content/50">Define the structure of your content</p>
              </div>
            </div>
            <span className="badge badge-ghost font-mono text-xs">{fields.length}</span>
          </div>
        </div>

        <div className="p-5">
          {fields.length > 0 ? (
            <FieldsBuilder contentType={contentType} fields={fields} onEdit={openEdit} />
          ) : (
            <div className="py-16 text-center">
              <div className="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-base-200 mb-4">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" className="text-base-content/40"><path d="M12 3v12"/><path d="m8 11 4 4 4-4"/><path d="M8 5H4a2 2 0 0 0-2 2v10a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2h-4"/></svg>
              </div>
              <h3 className="font-medium text-base-content/80 mb-1">No fields yet</h3>
              <p className="text-sm text-base-content/50 mb-5">Add fields to define what content editors can enter.</p>
              <AddFieldButton onClick={openNew}>Add your first field</AddFieldButton>
            </div>
          )}
        </div>
      </div>

      <div className="mt-8">
        <Link href={paths.content_types} className="btn btn-ghost btn-sm gap-2">
          <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m12 19-7-7 7-7"/><path d="M19 12H5"/></svg>
          Back to Content Types
        </Link>
      </div>

      <FieldDrawer
        open={drawer !== null}
        title={drawer?.field ? "Edit Field" : "Add Field"}
        onClose={close}
        contentType={contentType}
        field={drawer?.field ?? null}
        fieldTypes={fieldTypes}
        referenceTargets={referenceTargets}
        embeddableComponents={embeddableComponents}
      />
    </>
  )
}
