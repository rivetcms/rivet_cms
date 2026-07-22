import { createPortal } from "react-dom"

export default function EditorDialog({ title, onClose, onSubmit, submitLabel = "Apply", children }) {
  return createPortal(
    <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <form
        onClick={(e) => e.stopPropagation()}
        onSubmit={(e) => {
          e.preventDefault()
          e.stopPropagation()
          onSubmit()
        }}
        className="w-full max-w-sm overflow-hidden rounded-box border border-base-300 bg-base-100 shadow-xl"
      >
        <div className="border-b border-base-300 px-4 py-3 text-sm font-semibold">{title}</div>
        <div className="space-y-4 px-4 py-4">{children}</div>
        <div className="flex items-center justify-end gap-2 border-t border-base-200 px-4 py-3">
          <button type="button" className="btn btn-ghost btn-sm" onClick={onClose}>Cancel</button>
          <button type="submit" className="btn btn-primary btn-sm">{submitLabel}</button>
        </div>
      </form>
    </div>,
    document.body
  )
}
