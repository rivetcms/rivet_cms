import { Link, usePage } from "@inertiajs/react"

export default function Show() {
  const { paths } = usePage().props

  return (
    <div className="flex flex-col gap-6">
      <h1 className="text-2xl font-semibold">Dashboard</h1>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <div className="card bg-base-100 shadow-sm">
          <div className="card-body">
            <h2 className="card-title text-base">Content Types</h2>
            <p className="text-base-content/60 text-sm">Manage your content structure</p>
            <div className="card-actions justify-end mt-4">
              <Link href={paths.content_types} className="btn btn-primary btn-sm">View All</Link>
            </div>
          </div>
        </div>

        <div className="card bg-base-100 shadow-sm">
          <div className="card-body">
            <h2 className="card-title text-base">Components</h2>
            <p className="text-base-content/60 text-sm">Reusable content blocks</p>
            <div className="card-actions justify-end mt-4">
              <Link href={paths.components} className="btn btn-primary btn-sm">View All</Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
