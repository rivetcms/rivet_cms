import { router } from "@inertiajs/react"
import FieldTypeIcon from "./FieldTypeIcon"

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
      className={`field-item group relative bg-base-200/50 hover:bg-base-200 border border-base-300/50 hover:border-base-300 rounded-lg transition-all duration-150 cursor-move ${field.width === "full" ? "flex-1" : "w-1/2 flex-shrink-0"} ${dragging ? "opacity-40" : ""}`}
    >
      <div className="absolute top-3 right-3 cursor-grab active:cursor-grabbing opacity-0 group-hover:opacity-100 transition-opacity p-1 hover:bg-base-300 rounded">
        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-base-content/40">
          <circle cx="9" cy="5" r="1"/><circle cx="9" cy="12" r="1"/><circle cx="9" cy="19" r="1"/>
          <circle cx="15" cy="5" r="1"/><circle cx="15" cy="12" r="1"/><circle cx="15" cy="19" r="1"/>
        </svg>
      </div>

      <div className="p-4">
        <div className="flex items-start gap-3">
          <div className="shrink-0 w-9 h-9 rounded-lg bg-base-100 border border-base-300/50 flex items-center justify-center">
            <FieldTypeIcon fieldType={field.field_type} />
          </div>
          <div className="flex-1 min-w-0 pt-0.5">
            <div className="flex items-center gap-2 flex-wrap">
              <span className="font-medium text-sm truncate">{field.name}</span>
              {field.required && <span className="badge badge-warning badge-xs">Required</span>}
            </div>
            <div className="flex items-center gap-1.5 mt-1">
              <span className="text-xs text-base-content/50">{field.field_type_label}</span>
              <span className="text-base-content/30">&middot;</span>
              <span className="text-xs text-base-content/40 flex items-center gap-1">
                {field.width === "full" ? (
                  <>
                    <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect width="18" height="18" x="3" y="3" rx="2"/></svg>
                    Full
                  </>
                ) : (
                  <>
                    <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect width="7" height="18" x="3" y="3" rx="1"/><rect width="7" height="18" x="14" y="3" rx="1"/></svg>
                    Half
                  </>
                )}
              </span>
            </div>
          </div>
        </div>

        <div className="flex items-center gap-1 mt-3 pt-3 border-t border-base-300/30 opacity-0 group-hover:opacity-100 transition-opacity">
          <button type="button" className="btn btn-ghost btn-xs gap-1" onClick={() => onEdit(field)}>
            <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 20h9"/><path d="M16.376 3.622a1 1 0 0 1 3.002 3.002L7.368 18.635a2 2 0 0 1-.855.506l-2.872.838a.5.5 0 0 1-.62-.62l.838-2.872a2 2 0 0 1 .506-.854z"/></svg>
            Edit
          </button>

          <button type="button" className="btn btn-ghost btn-xs gap-1" onClick={toggleWidth}>
            {field.width === "full" ? (
              <>
                <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect width="7" height="18" x="3" y="3" rx="1"/><rect width="7" height="18" x="14" y="3" rx="1"/></svg>
                Make half
              </>
            ) : (
              <>
                <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect width="18" height="18" x="3" y="3" rx="2"/></svg>
                Make full
              </>
            )}
          </button>

          {field.paired && (
            <button type="button" className="btn btn-ghost btn-xs gap-1" onClick={unpair}>
              <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
              Unpair
            </button>
          )}

          <button type="button" className="btn btn-ghost btn-xs gap-1 text-error hover:bg-error/10" onClick={remove}>
            <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/><line x1="10" x2="10" y1="11" y2="17"/><line x1="14" x2="14" y1="11" y2="17"/></svg>
            Remove
          </button>
        </div>
      </div>
    </div>
  )
}
