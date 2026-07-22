import { Link, usePage, router } from "@inertiajs/react"
import EmptyState from "../../components/EmptyState"
import PageHeader from "../../components/PageHeader"

export default function Index({ components }) {
  const { paths } = usePage().props

  const destroy = (component) => {
    if (confirm(`Delete "${component.name}"? This cannot be undone.`)) router.delete(component.paths.destroy)
  }

  return (
    <>
      <PageHeader title="Components" description="Reusable blocks you can embed in content types.">
        <Link href={paths.new_component} className="btn btn-primary">New Component</Link>
      </PageHeader>

      {components.length === 0 ? (
        <EmptyState resourceName="Components" singularName="Component" newPath={paths.new_component} />
      ) : (
        <div className="overflow-x-auto rounded-box border border-base-300 bg-base-100">
          <table className="table">
            <thead>
              <tr className="text-[11px] uppercase tracking-wider text-base-content/50">
                <th>Name</th>
                <th>Slug</th>
                <th>Category</th>
                <th>Fields</th>
                <th className="w-24 text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {components.map((component) => (
                <tr key={component.id} className="hover">
                  <td>
                    <Link href={component.paths.show} className="font-medium hover:text-primary">
                      {component.name}
                    </Link>
                  </td>
                  <td>
                    <code className="rounded-selector bg-base-200 px-1.5 py-0.5 font-mono text-xs text-base-content/70">
                      {component.slug}
                    </code>
                  </td>
                  <td>
                    <span className="badge badge-ghost badge-sm">{component.category_name}</span>
                  </td>
                  <td>
                    <Link href={component.paths.show} className="badge badge-ghost badge-sm font-mono hover:badge-primary">
                      {component.fields_count}
                    </Link>
                  </td>
                  <td>
                    <div className="flex justify-end gap-0.5">
                      <Link href={component.paths.show} className="btn btn-ghost btn-sm btn-square" aria-label={`Open ${component.name}`}>
                        <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                          <path d="M5 12h14"/><path d="m12 5 7 7-7 7"/>
                        </svg>
                      </Link>
                      <button type="button" className="btn btn-ghost btn-sm btn-square text-error" onClick={() => destroy(component)} aria-label={`Delete ${component.name}`}>
                        <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                          <path d="M3 6h18"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>
                        </svg>
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </>
  )
}
