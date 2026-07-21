import { Link } from "@inertiajs/react"

export default function EmptyState({ resourceName, singularName, newPath }) {
  return (
    <div className="flex mt-10 flex-1 flex-col items-center justify-center gap-6">
      <div className="flex max-w-sm flex-col items-center gap-4 text-center">
        <div className="bg-base-200 text-base-content flex size-12 items-center justify-center rounded-lg">
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M10 10.5 8 13l2 2.5" /><path d="m14 10.5 2 2.5-2 2.5" /><path d="M20 20a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-7.9a2 2 0 0 1-1.69-.9L9.6 3.9A2 2 0 0 0 7.93 3H4a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2z" /></svg>
        </div>
        <div>
          <h3 className="text-lg font-medium">No {resourceName} yet</h3>
          <p className="text-base-content/60 text-sm mt-1">
            Get started by creating your first {singularName}.
          </p>
        </div>
        <div className="mt-2">
          <Link href={newPath} className="btn btn-primary">New {singularName}</Link>
        </div>
      </div>
    </div>
  )
}
