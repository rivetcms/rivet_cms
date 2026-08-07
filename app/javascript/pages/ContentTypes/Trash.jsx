import { Link, router, usePage } from "@inertiajs/react"
import PageHeader from "../../components/PageHeader"
import { timeAgo } from "../../lib/format"

export default function Trash({ content_types: contentTypes }) {
  const { paths } = usePage().props

  const restore = (contentType) => router.patch(contentType.paths.restore)

  return (
    <>
      <div className="mb-4">
        <Link href={paths.content_types} className="inline-flex items-center gap-1.5 text-[13px] font-medium text-base-content/50 transition-colors hover:text-base-content">
          <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m12 19-7-7 7-7"/><path d="M19 12H5"/></svg>
          Content Types
        </Link>
      </div>

      <PageHeader title="Removed content types" description="Nothing here is deleted. Restoring a type brings its entries back with it." />

      {contentTypes.length === 0 ? (
        <div className="rounded-box border border-dashed border-base-300 bg-base-100 py-16 text-center text-[13px] text-base-content/50">
          Nothing has been removed.
        </div>
      ) : (
        <div className="overflow-x-auto rounded-box border border-base-300 bg-base-100">
          <table className="table">
            <thead>
              <tr className="text-[11px] uppercase tracking-wider text-base-content/50">
                <th>Name</th>
                <th>Slug</th>
                {contentTypes[0].documents_count !== undefined && <th>Entries kept</th>}
                <th>Removed</th>
                <th className="w-24 text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {contentTypes.map((contentType) => (
                <tr key={contentType.id} className="hover">
                  <td className="font-medium">{contentType.name}</td>
                  <td>
                    <code className="rounded-selector bg-base-200 px-1.5 py-0.5 font-mono text-xs text-base-content/70">{contentType.slug}</code>
                  </td>
                  {contentType.documents_count !== undefined && (
                    <td className="font-mono text-xs tabular-nums">{contentType.documents_count}</td>
                  )}
                  <td className="text-[13px] text-base-content/50">{timeAgo(contentType.removed_at)}</td>
                  <td>
                    <div className="flex justify-end">
                      <button type="button" className="btn btn-ghost btn-sm border border-base-300" onClick={() => restore(contentType)}>
                        Restore
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
