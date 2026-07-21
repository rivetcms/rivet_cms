import { Link, usePage } from "@inertiajs/react"
import EmptyState from "../../components/EmptyState"

export default function Index({ content_types: contentTypes }) {
  const { paths } = usePage().props

  return (
    <>
      <div className="flex justify-between items-center mb-8">
        <h1 className="text-xl font-semibold">Content Types</h1>
        <Link href={paths.new_content_type} className="btn btn-primary">New Content Type</Link>
      </div>

      <div className="overflow-x-auto">
        <table className="table">
          <thead>
            <tr>
              <th>Name</th>
              <th>Slug</th>
              <th>Type</th>
              <th>Items</th>
              <th className="bg-base-100 sticky right-0">Actions</th>
            </tr>
          </thead>
          <tbody>
            {contentTypes.map((contentType) => (
              <tr key={contentType.id} className="hover">
                <td>{contentType.name}</td>
                <td>{contentType.slug}</td>
                <td>
                  <span className={`badge ${contentType.single ? "badge-primary" : "badge-secondary"}`}>
                    {contentType.single ? "Single" : "Collection"}
                  </span>
                </td>
                <td></td>
                <td className="bg-base-100 sticky right-0">
                  <div className="flex gap-1">
                    <Link href={contentType.paths.show} className="btn btn-ghost btn-sm btn-square">
                      <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                        <path d="M5 12h14"/><path d="m12 5 7 7-7 7"/>
                      </svg>
                    </Link>
                    <Link href={contentType.paths.edit} className="btn btn-ghost btn-sm btn-square">
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

      {contentTypes.length === 0 && (
        <EmptyState resourceName="Content Types" singularName="Content Type" newPath={paths.new_content_type} />
      )}
    </>
  )
}
