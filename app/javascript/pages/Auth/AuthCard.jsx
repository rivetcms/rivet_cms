import { usePage } from "@inertiajs/react"

// Bare-layout shell for the built-in auth screens: brand mark over a card,
// centered on the page. Pages using it set Component.layout = (page) => page.
export default function AuthCard({ title, description, children }) {
  const { props } = usePage()
  const errors = props.errors || {}
  const messages = Object.entries(errors).flatMap(([attr, list]) => {
    const items = Array.isArray(list) ? list : [list]
    return items.map((m) => (attr === "base" ? m : `${attr.replace(/_/g, " ")} ${m}`.replace(/^./, (c) => c.toUpperCase())))
  })

  return (
    <div className="flex min-h-screen items-center justify-center bg-base-200/50 p-4">
      <div className="w-full max-w-sm">
        <div className="mb-6 flex items-center justify-center gap-2.5">
          <div className="flex aspect-square size-9 items-center justify-center rounded-field bg-(--orange-5) text-[18px] font-bold text-white">R</div>
          <span className="text-[18px] font-bold tracking-tight">RivetCMS</span>
        </div>
        <div className="rounded-box border border-base-300 bg-base-100 p-6 shadow-(--shadow-raised)">
          <h1 className="text-[16px] font-semibold tracking-tight">{title}</h1>
          {description && <p className="mt-1 text-[13px] text-base-content/60">{description}</p>}
          {messages.length > 0 && (
            <div className="alert alert-error mt-4 px-3 py-2.5 text-[13px]">
              <div>{messages.map((m, i) => <p key={i}>{m}</p>)}</div>
            </div>
          )}
          <div className="mt-4">{children}</div>
        </div>
      </div>
    </div>
  )
}
