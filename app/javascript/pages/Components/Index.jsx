import { Link, usePage } from "@inertiajs/react"
import EmptyState from "../../components/EmptyState"

export default function Index({ components }) {
  const { paths } = usePage().props

  return (
    <>
      <div className="flex justify-between items-center mb-8">
        <h1 className="text-xl font-semibold">Components</h1>
        <Link href={paths.new_component} className="btn btn-primary">New Component</Link>
      </div>

      <div className="overflow-x-auto">
        <table className="table">
          <thead>
            <tr>
              <th>Name</th>
              <th>Slug</th>
              <th>Category</th>
              <th>Repeatable</th>
              <th className="bg-base-100 sticky right-0">Actions</th>
            </tr>
          </thead>
          <tbody>
            {components.map((component) => (
              <tr key={component.id} className="hover">
                <td>{component.name}</td>
                <td>{component.slug}</td>
                <td>
                  <span className="badge badge-ghost">{component.category_name}</span>
                </td>
                <td>
                  <span className={`badge ${component.repeatable ? "badge-success" : "badge-neutral"}`}>
                    {component.repeatable ? "Yes" : "No"}
                  </span>
                </td>
                <td className="bg-base-100 sticky right-0">
                  <div className="flex gap-1">
                    <Link href={component.paths.edit} className="btn btn-ghost btn-sm btn-square">
                      <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
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

      {components.length === 0 && (
        <EmptyState resourceName="Components" singularName="Component" newPath={paths.new_component} />
      )}
    </>
  )
}
