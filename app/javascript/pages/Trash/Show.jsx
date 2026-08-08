import { useState } from "react"
import { router } from "@inertiajs/react"
import PageHeader from "../../components/PageHeader"
import PurgeDialog from "../../components/PurgeDialog"
import FilterSelect from "../../components/FilterSelect"
import { timeAgo } from "../../lib/format"
import { useSearch } from "../../lib/use_search"

function SectionHeading({ children }) {
  return <h2 className="mb-2 mt-8 text-[11px] font-semibold uppercase tracking-wider text-base-content/40">{children}</h2>
}

function EmptyRow({ children }) {
  return (
    <div className="rounded-box border border-dashed border-base-300 bg-base-100 py-10 text-center text-[13px] text-base-content/50">
      {children}
    </div>
  )
}

export default function Show({ documents, content_types: contentTypes, types, pagination, q: initialQ, type: initialType }) {
  const [purging, setPurging] = useState(null)

  const visit = (params) => router.get(window.location.pathname, params, { preserveState: true, replace: true })
  const filterParams = (overrides = {}) => {
    const merged = { q: initialQ, type: initialType, ...overrides }
    return Object.fromEntries(Object.entries(merged).filter(([, v]) => v))
  }

  const [q, setQ] = useSearch(initialQ, (value) => visit(filterParams({ q: value })))

  const restore = (path) => router.patch(path)
  const goToPage = (page) => router.get(window.location.pathname, { ...filterParams(), page }, { preserveScroll: true })

  const purgeDocument = (document) => {
    const revisions = document.revision_count
    const detail = `${revisions} ${revisions === 1 ? "revision" : "revisions"}`
    if (confirm(`Permanently delete "${document.slug}" and its ${detail}? This cannot be undone.`)) {
      router.delete(document.paths.purge)
    }
  }

  const filtered = initialQ || initialType

  return (
    <>
      <PageHeader title="Trash" description="Nothing here is deleted. Restore anything to bring back its content and history." />

      <SectionHeading>Entries</SectionHeading>

      {(documents.length > 0 || filtered) && (
        <div className="mb-4 flex items-center gap-2">
          <input
            type="search"
            className="input input-bordered w-64"
            placeholder="Search by slug…"
            value={q}
            onChange={(e) => setQ(e.target.value)}
          />
          <FilterSelect
            options={types.map((type) => ({ value: type.slug, label: type.name }))}
            value={initialType}
            allLabel="All types"
            onChange={(slug) => visit(filterParams({ type: slug, q }))}
          />
          {(q || initialType) && (
            <button
              type="button"
              className="btn btn-ghost btn-sm btn-square"
              onClick={() => router.get(window.location.pathname, {}, { replace: true })}
              aria-label="Clear filters"
            >
              <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M18 6 6 18" /><path d="m6 6 12 12" /></svg>
            </button>
          )}
        </div>
      )}

      {documents.length === 0 ? (
        <EmptyRow>{filtered ? "No trashed entries match your filters." : "No trashed entries."}</EmptyRow>
      ) : (
        <div className="overflow-x-auto rounded-box border border-base-300 bg-base-100">
          <table className="table">
            <thead>
              <tr className="text-[11px] uppercase tracking-wider text-base-content/50">
                <th>Entry</th>
                <th>Type</th>
                <th>Status</th>
                <th>Author</th>
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
                  <td className="text-[13px]">{document.content_type_name}</td>
                  <td>
                    <span className={`badge badge-sm font-medium ${document.published ? "badge-success badge-soft" : "badge-ghost"}`}>
                      {document.published ? "Published" : "Draft"}
                    </span>
                  </td>
                  <td className="text-[13px]">{document.author}</td>
                  <td className="text-[13px] text-base-content/50">{timeAgo(document.trashed_at)}</td>
                  <td>
                    <div className="flex justify-end gap-1">
                      <button type="button" className="btn btn-ghost btn-sm border border-base-300" onClick={() => restore(document.paths.restore)}>
                        Restore
                      </button>
                      <button type="button" className="btn btn-ghost btn-sm text-error" onClick={() => purgeDocument(document)}>
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

      {pagination && pagination.total_pages > 1 && (
        <div className="mt-4 flex items-center justify-center gap-2">
          <button
            type="button"
            className="btn btn-ghost btn-sm border border-base-300"
            disabled={pagination.page <= 1}
            onClick={() => goToPage(pagination.page - 1)}
          >
            Previous
          </button>
          <span className="text-[13px] text-base-content/60">Page {pagination.page} of {pagination.total_pages}</span>
          <button
            type="button"
            className="btn btn-ghost btn-sm border border-base-300"
            disabled={pagination.page >= pagination.total_pages}
            onClick={() => goToPage(pagination.page + 1)}
          >
            Next
          </button>
        </div>
      )}

      {contentTypes.length > 0 && (
        <>
          <SectionHeading>Removed content types</SectionHeading>
          <div className="overflow-x-auto rounded-box border border-base-300 bg-base-100">
            <table className="table">
              <thead>
                <tr className="text-[11px] uppercase tracking-wider text-base-content/50">
                  <th>Name</th>
                  <th>Entries kept</th>
                  <th>Removed</th>
                  <th className="w-32 text-right">Actions</th>
                </tr>
              </thead>
              <tbody>
                {contentTypes.map((contentType) => (
                  <tr key={contentType.id} className="hover">
                    <td className="font-medium">{contentType.name}</td>
                    <td className="font-mono text-xs tabular-nums">{contentType.documents_count}</td>
                    <td className="text-[13px] text-base-content/50">{timeAgo(contentType.removed_at)}</td>
                    <td>
                      <div className="flex justify-end gap-1">
                        <button type="button" className="btn btn-ghost btn-sm border border-base-300" onClick={() => restore(contentType.paths.restore)}>
                          Restore
                        </button>
                        <button type="button" className="btn btn-ghost btn-sm text-error" onClick={() => setPurging(contentType)}>
                          Delete
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <p className="mt-2 text-[12px] text-base-content/50">
            Restoring a removed type brings its entries back with it.
          </p>
        </>
      )}

      {purging && <PurgeDialog contentType={purging} onClose={() => setPurging(null)} />}
    </>
  )
}
