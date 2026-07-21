import { router } from "@inertiajs/react"
import FieldTypeIcon from "./FieldTypeIcon"

function ActionButton({ label, onClick, danger = false, children }) {
  return (
    <div className="tooltip" data-tip={label}>
      <button
        type="button"
        className={`btn btn-ghost btn-xs btn-square ${danger ? "text-error hover:bg-error/10" : "text-base-content/60"}`}
        onClick={onClick}
        aria-label={label}
      >
        {children}
      </button>
    </div>
  )
}

export default function FieldCard({ field, onEdit, onDragStart, onDragEnd, dragging }) {
  const toggleWidth = () => {
    router.patch(field.paths.toggle_width, {}, { preserveScroll: true })
  }

  const unpair = () => {
    router.patch(field.paths.unpair, {}, { preserveScroll: true })
  }

  const remove = () => {
    if (confirm(`Remove "${field.name}"? This cannot be undone.`)) {
      router.delete(field.paths.destroy, { preserveScroll: true })
    }
  }

  return (
    <div
      draggable
      onDragStart={(e) => onDragStart(e, field)}
      onDragEnd={onDragEnd}
      className={`field-item group flex cursor-move items-center gap-2.5 rounded-field border border-base-300 bg-base-200/40 px-3 py-2.5 transition-all duration-150 hover:border-base-content/20 hover:bg-base-200/70 ${field.width === "full" ? "flex-1" : "w-1/2 flex-shrink-0"} ${dragging ? "opacity-40" : ""}`}
    >
      <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="shrink-0 text-base-content/25 transition-colors group-hover:text-base-content/50">
        <circle cx="9" cy="5" r="1"/><circle cx="9" cy="12" r="1"/><circle cx="9" cy="19" r="1"/>
        <circle cx="15" cy="5" r="1"/><circle cx="15" cy="12" r="1"/><circle cx="15" cy="19" r="1"/>
      </svg>

      <div className="flex size-8 shrink-0 items-center justify-center rounded-selector border border-base-300/60 bg-base-100">
        <FieldTypeIcon fieldType={field.field_type} size={14} />
      </div>

      <div className="min-w-0 flex-1">
        <div className="flex flex-wrap items-center gap-1.5">
          <span className="truncate text-[13px] font-medium">{field.name}</span>
          {field.required && <span className="badge badge-warning badge-soft badge-xs font-medium">Required</span>}
        </div>
        <div className="mt-0.5 flex items-center gap-1.5 text-[11px] text-base-content/50">
          <span>{field.field_type_label}</span>
          <span className="text-base-content/30">&middot;</span>
          <span>{field.width === "full" ? "Full width" : "Half width"}</span>
        </div>
      </div>

      <div className="flex shrink-0 items-center gap-0.5 opacity-0 transition-opacity group-hover:opacity-100">
        <ActionButton label="Edit" onClick={() => onEdit(field)}>
          <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 20h9"/><path d="M16.376 3.622a1 1 0 0 1 3.002 3.002L7.368 18.635a2 2 0 0 1-.855.506l-2.872.838a.5.5 0 0 1-.62-.62l.838-2.872a2 2 0 0 1 .506-.854z"/></svg>
        </ActionButton>

        <ActionButton label={field.width === "full" ? "Make half width" : "Make full width"} onClick={toggleWidth}>
          {field.width === "full" ? (
            <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect width="7" height="18" x="3" y="3" rx="1"/><rect width="7" height="18" x="14" y="3" rx="1"/></svg>
          ) : (
            <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect width="18" height="18" x="3" y="3" rx="2"/></svg>
          )}
        </ActionButton>

        {field.paired && (
          <ActionButton label="Unpair" onClick={unpair}>
            <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
          </ActionButton>
        )}

        <ActionButton label="Remove" onClick={remove} danger>
          <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/><line x1="10" x2="10" y1="11" y2="17"/><line x1="14" x2="14" y1="11" y2="17"/></svg>
        </ActionButton>
      </div>
    </div>
  )
}
