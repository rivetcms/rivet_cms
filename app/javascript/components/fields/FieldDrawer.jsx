import { useEffect } from "react"
import FieldForm from "./FieldForm"

export default function FieldDrawer({ open, title, onClose, ...formProps }) {
  useEffect(() => {
    const onKeydown = (e) => {
      if (e.key === "Escape") onClose()
    }
    addEventListener("keydown", onKeydown)
    return () => removeEventListener("keydown", onKeydown)
  }, [onClose])

  return (
    <div className="drawer drawer-end">
      <input type="checkbox" className="drawer-toggle" checked={open} readOnly />

      <div className="drawer-side z-50">
        <label aria-label="close sidebar" className="drawer-overlay" onClick={onClose}></label>

        <div className="bg-base-100 min-h-full w-full sm:w-[400px] flex flex-col shadow-2xl">
          <div className="flex items-center justify-between border-b border-base-200 px-5 py-3.5">
            <h3 className="text-[15px] font-semibold tracking-tight">{title}</h3>
            <button type="button" className="btn btn-ghost btn-xs btn-square" onClick={onClose} aria-label="Close">
              <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M18 6 6 18"/><path d="m6 6 12 12"/>
              </svg>
            </button>
          </div>

          <div className="flex-1 overflow-y-auto p-5">
            {open && <FieldForm onClose={onClose} {...formProps} />}
          </div>
        </div>
      </div>
    </div>
  )
}
