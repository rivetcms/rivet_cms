import { Link, router } from "@inertiajs/react"
import PageHeader from "../../components/PageHeader"
import EmptyState from "../../components/EmptyState"
import { useSearch } from "../../lib/use_search"

export default function Index({ content_type: contentType, documents, q: initialQ }) {
  const [q, setQ] = useSearch(initialQ, (value) =>
    router.get(contentType.paths.documents, value ? { q: value } : {}, { preserveState: true, replace: true })
  )

  const destroy = (document) => {
    if (confirm("Delete this entry? This cannot be undone.")) router.delete(document.paths.destroy)
  }

  return (
    <>
      <div className="mb-4">
        <Link href={contentType.paths.show} className="inline-flex items-center gap-1.5 text-[13px] font-medium text-base-content/50 transition-colors hover:text-base-content">
          <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m12 19-7-7 7-7"/><path d="M19 12H5"/></svg>
          {contentType.name}
        </Link>
      </div>

      <PageHeader title={`${contentType.name} entries`} description="Create and publish content entries.">
        <Link href={contentType.paths.new_document} className="btn btn-primary">New Entry</Link>
      </PageHeader>

      {(documents.length > 0 || initialQ) && (
        <div className="mb-4">
          <input
            type="search"
            className="input input-bordered w-64"
            placeholder="Search by slug…"
            value={q}
            onChange={(e) => setQ(e.target.value)}
          />
        </div>
      )}

      {documents.length === 0 && !initialQ ? (
        <EmptyState resourceName="Entries" singularName="Entry" newPath={contentType.paths.new_document} />
      ) : documents.length === 0 ? (
        <div className="rounded-box border border-dashed border-base-300 bg-base-100 py-16 text-center text-[13px] text-base-content/50">
          No entries match "{initialQ}".
        </div>
      ) : (
        <div className="overflow-x-auto rounded-box border border-base-300 bg-base-100">
          <table className="table">
            <thead>
              <tr className="text-[11px] uppercase tracking-wider text-base-content/50">
                <th>Slug</th>
                <th>Status</th>
                <th className="w-24 text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {documents.map((document) => (
                <tr key={document.id} className="hover">
                  <td>
                    <Link href={document.paths.edit} className="font-medium hover:text-primary">{document.slug}</Link>
                  </td>
                  <td>
                    <span className={`badge badge-sm font-medium ${document.published ? "badge-success badge-soft" : "badge-ghost"}`}>
                      {document.published ? "Published" : "Draft"}
                    </span>
                  </td>
                  <td>
                    <div className="flex justify-end gap-0.5">
                      <Link href={document.paths.edit} className="btn btn-ghost btn-sm btn-square" aria-label={`Edit ${document.slug}`}>
                        <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 3H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.375 2.625a1 1 0 0 1 3 3l-9.013 9.014a2 2 0 0 1-.853.505l-2.873.84a.5.5 0 0 1-.62-.62l.84-2.873a2 2 0 0 1 .506-.852z"/></svg>
                      </Link>
                      <button type="button" className="btn btn-ghost btn-sm btn-square text-error" onClick={() => destroy(document)} aria-label={`Delete ${document.slug}`}>
                        <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 6h18"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>
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
