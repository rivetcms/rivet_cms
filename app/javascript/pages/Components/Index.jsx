import { Link, usePage } from "@inertiajs/react"
import EmptyState from "../../components/EmptyState"
import PageHeader from "../../components/PageHeader"

export default function Index({ components }) {
  const { paths } = usePage().props

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
                <th>Repeatable</th>
                <th className="w-16 text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {components.map((component) => (
                <tr key={component.id} className="hover">
                  <td>
                    <Link href={component.paths.edit} className="font-medium hover:text-primary">
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
                    {component.repeatable ? (
                      <span className="badge badge-success badge-soft badge-sm font-medium">Yes</span>
                    ) : (
                      <span className="badge badge-ghost badge-sm">No</span>
                    )}
                  </td>
                  <td>
                    <div className="flex justify-end">
                      <Link href={component.paths.edit} className="btn btn-ghost btn-sm btn-square" aria-label={`Edit ${component.name}`}>
                        <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                          <path d="M12 3H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.375 2.625a1 1 0 0 1 3 3l-9.013 9.014a2 2 0 0 1-.853.505l-2.873.84a.5.5 0 0 1-.62-.62l.84-2.873a2 2 0 0 1 .506-.852z"/>
                        </svg>
                      </Link>
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
