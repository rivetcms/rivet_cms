import { useEffect, useState } from "react"
import { usePage } from "@inertiajs/react"

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
        <div className="alert alert-error px-3.5 py-2.5 text-[13px] shadow-lg">
          <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10"/><path d="m15 9-6 6"/><path d="m9 9 6 6"/></svg>
          <span>{flash.alert}</span>
          <button type="button" className="btn btn-ghost btn-xs btn-square" onClick={() => setVisible(false)} aria-label="Dismiss">
            <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
          </button>
        </div>
      )}
      {flash.notice && (
        <div className="alert alert-success px-3.5 py-2.5 text-[13px] shadow-lg">
          <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21.801 10A10 10 0 1 1 17 3.335"/><path d="m9 11 3 3L22 4"/></svg>
          <span>{flash.notice}</span>
        </div>
      )}
    </div>
  )
}
