import { Link, usePage } from "@inertiajs/react"
import PageHeader from "../../components/PageHeader"
import EmptyState from "../../components/EmptyState"

export default function Index({ content_types: contentTypes }) {
  const { paths } = usePage().props

  return (
    <>
      <PageHeader title="Content" description="Create and publish entries for your content types." />

      {contentTypes.length === 0 ? (
        <EmptyState resourceName="Content Types" singularName="Content Type" newPath={paths.new_content_type} />
      ) : (
        <div className="grid gap-3 sm:grid-cols-2">
          {contentTypes.map((contentType) => (
            <Link
              key={contentType.id}
              href={contentType.paths.documents}
              className="group flex items-center justify-between rounded-box border border-base-300 bg-base-100 p-4 transition-colors hover:border-primary/40"
            >
              <div className="min-w-0">
                <div className="flex items-center gap-2">
                  <span className="truncate text-[15px] font-semibold">{contentType.name}</span>
                  <span className={`badge badge-sm font-medium ${contentType.single ? "badge-warning badge-soft" : "badge-info badge-soft"}`}>
                    {contentType.single ? "Single" : "Collection"}
                  </span>
                </div>
                <code className="mt-1 inline-block rounded-selector bg-base-200 px-1.5 py-0.5 font-mono text-xs text-base-content/70">
                  {contentType.slug}
                </code>
              </div>
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="shrink-0 text-base-content/30 transition-colors group-hover:text-primary">
                <path d="M5 12h14"/><path d="m12 5 7 7-7 7"/>
              </svg>
            </Link>
          ))}
        </div>
      )}
    </>
  )
}
