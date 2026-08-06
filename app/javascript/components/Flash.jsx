import { useEffect, useState } from "react"
import { usePage } from "@inertiajs/react"

// Lifted semantic hues; the theme's -5 values are too dark on the inverse surface
const TONES = {
  success: "#5fbd7e",
  danger: "#f2735e",
}

function Toast({ tone, children, onDismiss }) {
  return (
    <div
      className="flex max-w-md items-center gap-2.5 rounded-field bg-neutral py-3 pl-3.5 pr-2.5 text-[13px] text-neutral-content shadow-(--shadow-raised)"
      style={{ borderLeft: `3px solid ${TONES[tone]}` }}
    >
      {children}
    </div>
  )
}

export default function Flash() {
  const { flash } = usePage().props
  const [visible, setVisible] = useState(true)

  useEffect(() => {
    setVisible(true)
    if (flash?.notice) {
      const timer = setTimeout(() => setVisible(false), 4000)
      return () => clearTimeout(timer)
    }
  }, [flash])

  if (!flash || !visible) return null

  return (
    <div className="toast toast-top toast-end z-50">
      {flash.alert && (
        <Toast tone="danger">
          <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke={TONES.danger} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10"/><path d="m15 9-6 6"/><path d="m9 9 6 6"/></svg>
          <span className="flex-1">{flash.alert}</span>
          <button type="button" className="flex p-1 opacity-75 transition-opacity hover:opacity-100" onClick={() => setVisible(false)} aria-label="Dismiss">
            <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
          </button>
        </Toast>
      )}
      {flash.notice && (
        <Toast tone="success">
          <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke={TONES.success} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21.801 10A10 10 0 1 1 17 3.335"/><path d="m9 11 3 3L22 4"/></svg>
          <span className="flex-1">{flash.notice}</span>
        </Toast>
      )}
    </div>
  )
}
