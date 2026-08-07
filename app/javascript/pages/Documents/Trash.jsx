import { Link, router } from "@inertiajs/react"
import PageHeader from "../../components/PageHeader"
import { timeAgo } from "../../lib/format"

export default function Trash({ content_type: contentType, documents }) {
  const restore = (document) => router.patch(document.paths.restore)

  const purge = (document) => {
    const revisions = document.revision_count
    const detail = `${revisions} ${revisions === 1 ? "revision" : "revisions"}`
    if (confirm(`Permanently delete "${document.slug}" and its ${detail}? This cannot be undone.`)) {
      router.delete(document.paths.purge)
    }
  }

  return (
    <>
      <div className="mb-4">
        <Link href={contentType.paths.documents} className="inline-flex items-center gap-1.5 text-[13px] font-medium text-base-content/50 transition-colors hover:text-base-content">
          <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m12 19-7-7 7-7"/><path d="M19 12H5"/></svg>
          {contentType.name} entries
        </Link>
      </div>

      <PageHeader title="Trashed entries" description="Nothing here is deleted. Restoring an entry brings back its content and history." />

      {documents.length === 0 ? (
        <div className="rounded-box border border-dashed border-base-300 bg-base-100 py-16 text-center text-[13px] text-base-content/50">
          Nothing has been trashed.
        </div>
      ) : (
        <div className="overflow-x-auto rounded-box border border-base-300 bg-base-100">
          <table className="table">
            <thead>
              <tr className="text-[11px] uppercase tracking-wider text-base-content/50">
                <th>Entry</th>
                <th>Revisions kept</th>
                <th>Trashed</th>
                <th className="w-32 text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {documents.map((document) => (
                <tr key={document.id} className="hover">
                  <td>
                    <span className="block font-medium">{document.title || document.slug}</span>
                    <span className="block font-mono text-[11px] text-base-content/50">{document.slug}</span>
                  </td>
                  <td className="font-mono text-xs tabular-nums">{document.revision_count}</td>
                  <td className="text-[13px] text-base-content/50">{timeAgo(document.trashed_at)}</td>
                  <td>
                    <div className="flex justify-end gap-1">
                      <button type="button" className="btn btn-ghost btn-sm border border-base-300" onClick={() => restore(document)}>
                        Restore
                      </button>
                      <button type="button" className="btn btn-ghost btn-sm text-error" onClick={() => purge(document)}>
                        Delete
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
