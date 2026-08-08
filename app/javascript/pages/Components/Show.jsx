import { useState } from "react"
import { Link, usePage, router } from "@inertiajs/react"
import PageHeader from "../../components/PageHeader"
import ComponentForm from "../../components/ComponentForm"
import SettingsModal from "../../components/SettingsModal"
import FieldsBuilder from "../../components/fields/FieldsBuilder"
import FieldDrawer from "../../components/fields/FieldDrawer"
import { useConfirm } from "../../lib/confirm"

function AddFieldButton({ onClick, children }) {
  return (
    <button type="button" className="btn btn-primary gap-1.5" onClick={onClick}>
      <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M5 12h14"/><path d="M12 5v14"/></svg>
      {children}
    </button>
  )
}

export default function Show({
  component,
  categories,
  create_category_path: createCategoryPath,
  fields,
  field_types: fieldTypes,
  reference_targets: referenceTargets,
  embeddable_components: embeddableComponents,
}) {
  const confirm = useConfirm()
  const { paths } = usePage().props
  const [drawer, setDrawer] = useState(null)
  const [settingsOpen, setSettingsOpen] = useState(false)

  const openNew = () => setDrawer({ field: null })
  const openEdit = (field) => setDrawer({ field })
  const close = () => setDrawer(null)

  const destroy = async () => {
    const ok = await confirm({
      title: `Delete "${component.name}"?`,
      message: "This cannot be undone.",
      confirmLabel: "Delete",
      danger: true,
    })
    if (ok) {
      router.delete(component.paths.destroy)
    }
  }

  return (
    <>
      <div className="mb-4">
        <Link href={paths.components} className="inline-flex items-center gap-1.5 text-[13px] font-medium text-base-content/50 transition-colors hover:text-base-content">
          <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m12 19-7-7 7-7"/><path d="M19 12H5"/></svg>
          Components
        </Link>
      </div>

      <PageHeader
        title={component.name}
        meta={component.category_name && <span className="badge badge-ghost badge-sm">{component.category_name}</span>}
        description={
          <code className="rounded-selector bg-base-200 px-1.5 py-0.5 font-mono text-xs text-base-content/70">
            {component.slug}
          </code>
        }
      >
        <button type="button" className="btn btn-ghost gap-1.5 border border-base-300 bg-base-100 text-error" onClick={destroy}>
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 6h18"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>
          Delete
        </button>
        <button type="button" className="btn btn-ghost gap-1.5 border border-base-300 bg-base-100" onClick={() => setSettingsOpen(true)}>
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/></svg>
          Settings
        </button>
        <AddFieldButton onClick={openNew}>Add Field</AddFieldButton>
      </PageHeader>

      <div className="rounded-box border border-base-300 bg-base-100">
        <div className="flex items-center justify-between border-b border-base-200 px-5 py-3.5">
          <div>
            <h2 className="text-sm font-semibold">Fields</h2>
            <p className="text-xs text-base-content/50">Define what this component contains</p>
          </div>
          <span className="badge badge-ghost badge-sm font-mono">{fields.length}</span>
        </div>

        <div className="p-4">
          {fields.length > 0 ? (
            <FieldsBuilder owner={component} fields={fields} onEdit={openEdit} />
          ) : (
            <div className="py-14 text-center">
              <div className="mb-3 inline-flex size-11 items-center justify-center rounded-box bg-base-200">
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" className="text-base-content/40"><path d="M12 3v12"/><path d="m8 11 4 4 4-4"/><path d="M8 5H4a2 2 0 0 0-2 2v10a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2h-4"/></svg>
              </div>
              <h3 className="text-sm font-medium">No fields yet</h3>
              <p className="mb-4 mt-0.5 text-[13px] text-base-content/50">Add fields to define what this component contains.</p>
              <AddFieldButton onClick={openNew}>Add your first field</AddFieldButton>
            </div>
          )}
        </div>
      </div>

      <SettingsModal open={settingsOpen} title={`${component.name} settings`} onClose={() => setSettingsOpen(false)}>
        <ComponentForm
          component={component}
          categories={categories}
          createCategoryPath={createCategoryPath}
          submitLabel="Save Changes"
          onCancel={() => setSettingsOpen(false)}
        />
      </SettingsModal>

      <FieldDrawer
        open={drawer !== null}
        title={drawer?.field ? "Edit Field" : "Add Field"}
        onClose={close}
        owner={component}
        field={drawer?.field ?? null}
        fieldTypes={fieldTypes}
        referenceTargets={referenceTargets}
        embeddableComponents={embeddableComponents}
      />
    </>
  )
}
