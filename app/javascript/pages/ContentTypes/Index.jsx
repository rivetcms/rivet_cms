import { Link, usePage, router } from "@inertiajs/react"
import EmptyState from "../../components/EmptyState"
import PageHeader from "../../components/PageHeader"
import { useConfirm } from "../../lib/confirm"

export default function Index({ content_types: contentTypes, removed_count: removedCount }) {
  const confirm = useConfirm()
  const { paths } = usePage().props

  const destroy = async (contentType) => {
    const ok = await confirm({
      title: `Remove "${contentType.name}"?`,
      message: "Its entries are kept and you can restore it from the trash.",
      confirmLabel: "Remove",
    })
    if (ok) {
      router.delete(contentType.paths.destroy)
    }
  }

  return (
    <>
      <PageHeader title="Content Types" description="Define the structure of your content.">
        {removedCount > 0 && (
          <Link href={paths.content_types_trash} className="btn btn-ghost border border-base-300">
            Trash
            <span className="badge badge-sm font-mono">{removedCount}</span>
          </Link>
        )}
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
                <th>Entries</th>
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
                  <td>
                    {contentType.documents_count !== undefined && (
                      <Link href={contentType.paths.documents} className="badge badge-ghost badge-sm font-mono hover:badge-primary">
                        {contentType.documents_count}
                      </Link>
                    )}
                  </td>
                  <td>
                    <div className="flex justify-end gap-0.5">
                      <Link href={contentType.paths.show} className="btn btn-ghost btn-sm btn-square" aria-label={`Open ${contentType.name}`}>
                        <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                          <path d="M5 12h14"/><path d="m12 5 7 7-7 7"/>
                        </svg>
                      </Link>
                      <button type="button" className="btn btn-ghost btn-sm btn-square text-error" onClick={() => destroy(contentType)} aria-label={`Delete ${contentType.name}`}>
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
