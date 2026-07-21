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
    <>
      {flash.alert && (
        <div className="alert alert-error max-w-2xl mx-auto mb-4">
          <svg xmlns="http://www.w3.org/2000/svg" className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <span>{flash.alert}</span>
        </div>
      )}
      {flash.notice && (
        <div className="toast toast-top toast-end z-50">
          <div className="alert alert-success">
            <svg xmlns="http://www.w3.org/2000/svg" className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <span>{flash.notice}</span>
          </div>
        </div>
      )}
    </>
  )
}
