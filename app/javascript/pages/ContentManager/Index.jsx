import { Link, router, usePage } from "@inertiajs/react"
import PageHeader from "../../components/PageHeader"
import EmptyState from "../../components/EmptyState"
import FilterSelect from "../../components/FilterSelect"
import { timeAgo } from "../../lib/format"
import { useSearch } from "../../lib/use_search"

export default function Index({ content_types: contentTypes, documents, pagination, q: initialQ, type: initialType }) {
  const { paths } = usePage().props

  const visit = (params) => router.get(paths.content, params, { preserveState: true, replace: true })
  const filterParams = (overrides = {}) => {
    const merged = { q: initialQ, type: initialType, ...overrides }
    return Object.fromEntries(Object.entries(merged).filter(([, v]) => v))
  }

  const [q, setQ] = useSearch(initialQ, (value) => visit(filterParams({ q: value })))

  const destroy = (document) => {
    if (confirm("Move this entry to the trash? You can restore it later.")) router.delete(document.paths.destroy)
  }

  const goToPage = (page) =>
    router.get(paths.content, { ...filterParams(), page }, { preserveScroll: true })

  const filtered = initialQ || initialType

  return (
    <>
      <PageHeader title="Content" description="Entries across all content types.">
        {contentTypes.length > 0 && (
          <div className="dropdown dropdown-end">
            <div tabIndex={0} role="button" className="btn btn-primary">New Entry</div>
            <ul tabIndex={0} className="dropdown-content menu z-10 mt-1 max-h-80 w-52 flex-nowrap overflow-y-auto rounded-box border border-base-300 bg-base-100 p-1.5 shadow-(--shadow-raised)">
              {contentTypes.map((type) => (
                <li key={type.id}>
                  <Link href={type.paths.new_document} className="text-[13px]">{type.name}</Link>
                </li>
              ))}
            </ul>
          </div>
        )}
      </PageHeader>

      {contentTypes.length === 0 ? (
        <EmptyState resourceName="Content Types" singularName="Content Type" newPath={paths.new_content_type} />
      ) : (
        <>
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
                options={contentTypes.map((type) => ({ value: type.slug, label: type.name }))}
                value={initialType}
                allLabel="All types"
                onChange={(slug) => visit(filterParams({ type: slug, q }))}
              />
              {(q || initialType) && (
                <button
                  type="button"
                  className="btn btn-ghost btn-sm btn-square"
                  onClick={() => router.get(paths.content, {}, { replace: true })}
                  aria-label="Clear filters"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
                </button>
              )}
            </div>
          )}

          {documents.length === 0 ? (
            <div className="rounded-box border border-dashed border-base-300 bg-base-100 py-16 text-center text-[13px] text-base-content/50">
              {filtered ? "No entries match your filters." : "No entries yet. Create one with New Entry."}
            </div>
          ) : (
            <div className="overflow-x-auto rounded-box border border-base-300 bg-base-100">
              <table className="table">
                <thead>
                  <tr className="text-[11px] uppercase tracking-wider text-base-content/50">
                    <th>Entry</th>
                    <th>Type</th>
                    <th>Status</th>
                    <th>Author</th>
                    <th>Updated</th>
                    <th className="w-24 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {documents.map((document) => (
                    <tr key={document.id} className="hover">
                      <td>
                        <Link href={document.paths.edit} className="group block">
                          <span className="block font-medium group-hover:text-primary">{document.title || document.slug}</span>
                          <span className="block font-mono text-[11px] text-base-content/50">{document.slug}</span>
                        </Link>
                      </td>
                      <td className="text-[13px] text-base-content/70">{document.content_type_name}</td>
                      <td>
                        <span className={`badge badge-sm font-medium ${document.published ? "badge-success badge-soft" : "badge-ghost"}`}>
                          {document.published ? "Published" : "Draft"}
                        </span>
                      </td>
                      <td className="text-[13px] text-base-content/70">{document.author}</td>
                      <td className="text-[13px] text-base-content/50">{timeAgo(document.updated_at)}</td>
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
        </>
      )}
    </>
  )
}
