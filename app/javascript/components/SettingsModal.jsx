import { useEffect } from "react"
import { createPortal } from "react-dom"

export default function SettingsModal({ open, title, onClose, children }) {
  useEffect(() => {
    if (!open) return
    const onKey = (e) => e.key === "Escape" && onClose()
    window.addEventListener("keydown", onKey)
    return () => window.removeEventListener("keydown", onKey)
  }, [open, onClose])

  if (!open) return null

  return createPortal(
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
      onClick={onClose}
      onDragOver={(e) => e.preventDefault()}
      onDrop={(e) => e.preventDefault()}
    >
      <div className="w-full max-w-lg overflow-hidden rounded-box border border-base-300 bg-base-100 shadow-(--shadow-overlay)" onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between border-b border-base-300 px-5 py-3.5">
          <h2 className="text-[15px] font-semibold tracking-tight">{title}</h2>
          <button type="button" className="btn btn-ghost btn-xs btn-square" onClick={onClose} aria-label="Close">
            <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
          </button>
        </div>
        <div className="max-h-[70vh] overflow-y-auto p-5">{children}</div>
      </div>
    </div>,
    document.body
  )
}
