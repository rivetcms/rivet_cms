import { Link } from "@inertiajs/react"

export default function EmptyState({ resourceName, singularName, newPath }) {
  return (
    <div className="rounded-box border border-dashed border-base-300 bg-base-100 py-16">
      <div className="mx-auto flex max-w-sm flex-col items-center gap-3 text-center">
        <div className="flex size-11 items-center justify-center rounded-box bg-base-200 text-base-content/60">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"><path d="M10 10.5 8 13l2 2.5" /><path d="m14 10.5 2 2.5-2 2.5" /><path d="M20 20a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-7.9a2 2 0 0 1-1.69-.9L9.6 3.9A2 2 0 0 0 7.93 3H4a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2z" /></svg>
        </div>
        <div>
          <h3 className="text-sm font-semibold">No {resourceName} yet</h3>
          <p className="mt-0.5 text-[13px] text-base-content/50">
            Get started by creating your first {singularName.toLowerCase()}.
          </p>
        </div>
        <Link href={newPath} className="btn btn-primary btn-sm mt-1.5">New {singularName}</Link>
      </div>
    </div>
  )
}
