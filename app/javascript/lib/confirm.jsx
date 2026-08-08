import { createContext, useCallback, useContext, useEffect, useRef, useState } from "react"
import { createPortal } from "react-dom"

// Branded replacement for window.confirm. Promise-based so call sites stay
// one-liners:
//
//   const confirm = useConfirm()
//   if (await confirm({ title: "Delete?", message: "...", danger: true })) ...
//
// Built on the native <dialog> with showModal(), which supplies focus
// containment, background inertness, Escape-to-cancel, and restoring focus
// to the opener when the dialog closes. danger renders a red confirm button
// and puts initial focus on Cancel; the backdrop always cancels.
const ConfirmContext = createContext(null)

function ConfirmModal({ title, message, confirmLabel, danger, onResolve }) {
  const dialogRef = useRef(null)
  const doneRef = useRef(false)

  const resolve = (answer) => {
    if (doneRef.current) return
    doneRef.current = true
    dialogRef.current?.close()
    onResolve(answer)
  }

  useEffect(() => {
    const dialog = dialogRef.current
    dialog.showModal()
    dialog.querySelector(danger ? "[data-cancel]" : "[data-confirm]")?.focus()
  }, [danger])

  return createPortal(
    <dialog
      ref={dialogRef}
      role="alertdialog"
      aria-labelledby="rivet-confirm-title"
      aria-describedby={message ? "rivet-confirm-message" : undefined}
      className="w-full max-w-sm rounded-box border border-base-300 bg-base-100 p-5 text-base-content shadow-(--shadow-overlay) backdrop:bg-black/40"
      onClose={() => resolve(false)}
      onClick={(e) => e.target === dialogRef.current && resolve(false)}
    >
      <h2 id="rivet-confirm-title" className="text-[15px] font-semibold tracking-tight">{title}</h2>
      {message && <p id="rivet-confirm-message" className="mt-2 text-[13px] leading-relaxed text-base-content/70">{message}</p>}
      <div className="mt-5 flex justify-end gap-2">
        <button type="button" data-cancel className="btn btn-ghost" onClick={() => resolve(false)}>
          Cancel
        </button>
        <button
          type="button"
          data-confirm
          className={`btn ${danger ? "btn-error" : "btn-primary"}`}
          onClick={() => resolve(true)}
        >
          {confirmLabel || "Confirm"}
        </button>
      </div>
    </dialog>,
    document.body
  )
}

export function ConfirmProvider({ children }) {
  const [pending, setPending] = useState(null)

  const confirm = useCallback(
    (options) => new Promise((resolve) => setPending({ ...options, resolve })),
    []
  )

  const resolvePending = (answer) => {
    pending.resolve(answer)
    setPending(null)
  }

  return (
    <ConfirmContext.Provider value={confirm}>
      {children}
      {pending && <ConfirmModal key={pending.title} {...pending} onResolve={resolvePending} />}
    </ConfirmContext.Provider>
  )
}

export function useConfirm() {
  const confirm = useContext(ConfirmContext)
  // Outside the provider (shouldn't happen in the admin) fall back to the
  // native dialog rather than breaking the action.
  return confirm || ((options) => Promise.resolve(window.confirm([options.title, options.message].filter(Boolean).join(" "))))
}
