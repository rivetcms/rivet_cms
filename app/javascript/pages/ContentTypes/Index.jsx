import { Link, usePage } from "@inertiajs/react"
import EmptyState from "../../components/EmptyState"
import PageHeader from "../../components/PageHeader"

export default function Index({ content_types: contentTypes }) {
  const { paths } = usePage().props

  return (
    <>
      <PageHeader title="Content Types" description="Define the structure of your content.">
        <Link href={paths.new_content_type} className="btn btn-primary">New Content Type</Link>
      </PageHeader>

      {contentTypes.length === 0 ? (
        <EmptyState resourceName="Content Types" singularName="Content Type" newPath={paths.new_content_type} />
      ) : (
        <div className="overflow-x-auto rounded-box border border-base-300 bg-base-100">
          <table className="table">
            <thead>
              <tr className="text-[11px] uppercase tracking-wider text-base-content/50">
                <th>Name</th>
                <th>Slug</th>
                <th>Type</th>
                <th>Items</th>
                <th className="w-24 text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {contentTypes.map((contentType) => (
                <tr key={contentType.id} className="hover">
                  <td>
                    <Link href={contentType.paths.show} className="font-medium hover:text-primary">
                      {contentType.name}
                    </Link>
                  </td>
                  <td>
                    <code className="rounded-selector bg-base-200 px-1.5 py-0.5 font-mono text-xs text-base-content/70">
                      {contentType.slug}
                    </code>
                  </td>
                  <td>
                    <span className={`badge badge-sm font-medium ${contentType.single ? "badge-warning badge-soft" : "badge-info badge-soft"}`}>
                      {contentType.single ? "Single" : "Collection"}
                    </span>
                  </td>
                  <td></td>
                  <td>
                    <div className="flex justify-end gap-0.5">
                      <Link href={contentType.paths.show} className="btn btn-ghost btn-sm btn-square" aria-label={`Open ${contentType.name}`}>
                        <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                          <path d="M5 12h14"/><path d="m12 5 7 7-7 7"/>
                        </svg>
                      </Link>
                      <Link href={contentType.paths.edit} className="btn btn-ghost btn-sm btn-square" aria-label={`Edit ${contentType.name}`}>
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
