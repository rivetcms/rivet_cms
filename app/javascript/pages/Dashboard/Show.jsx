import { Link, usePage } from "@inertiajs/react"
import PageHeader from "../../components/PageHeader"
import { timeAgo } from "../../lib/format"

function StatTile({ href, label, value }) {
  return (
    <Link
      href={href}
      className="rounded-box border border-base-300 bg-base-100 px-4 py-3.5 shadow-(--shadow-card) transition-colors hover:border-base-content/30"
    >
      <div className="text-[11px] font-semibold uppercase tracking-wider text-base-content/50">{label}</div>
      <div className="mt-1 font-mono text-2xl font-medium tabular-nums">{value}</div>
    </Link>
  )
}

function Panel({ title, action, children }) {
  return (
    <section className="rounded-box border border-base-300 bg-base-100 shadow-(--shadow-card)">
      <div className="flex items-center justify-between border-b border-base-200 px-4 py-3">
        <h2 className="text-[13px] font-semibold">{title}</h2>
        {action}
      </div>
      {children}
    </section>
  )
}

function StatusBadge({ published }) {
  return (
    <span className={`badge badge-sm font-medium ${published ? "badge-success badge-soft" : "badge-ghost"}`}>
      {published ? "Published" : "Draft"}
    </span>
  )
}

function RecentEntries({ documents }) {
  return (
    <Panel title="Recent entries">
      <table className="table">
        <thead>
          <tr className="text-[11px] uppercase tracking-wider text-base-content/50">
            <th>Entry</th>
            <th>Type</th>
            <th>Status</th>
            <th className="text-right">Updated</th>
          </tr>
        </thead>
        <tbody>
          {documents.map((document) => (
            <tr key={document.id} className="hover">
              <td>
                <Link href={document.paths.edit} className="font-mono text-xs font-medium hover:underline">
                  {document.slug}
                </Link>
              </td>
              <td className="text-[13px] text-base-content/70">{document.content_type_name}</td>
              <td><StatusBadge published={document.published} /></td>
              <td className="text-right text-[13px] text-base-content/50">{timeAgo(document.updated_at)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </Panel>
  )
}

function ByType({ contentTypes }) {
  const max = Math.max(...contentTypes.map((t) => t.entry_count), 1)

  return (
    <Panel title="Entries by type">
      <ul className="p-2">
        {contentTypes.map((type) => (
          <li key={type.id}>
            <Link
              href={type.paths.documents}
              className="flex items-center gap-3 rounded-field px-2.5 py-2 transition-colors hover:bg-base-200"
            >
              <span className="w-1/3 truncate text-[13px] font-medium">{type.name}</span>
              <span className="h-[3px] flex-1 bg-base-200">
                <span
                  className="block h-full bg-base-content/50"
                  style={{ width: `${(type.entry_count / max) * 100}%` }}
                />
              </span>
              <span className="font-mono text-xs tabular-nums text-base-content/70">{type.entry_count}</span>
            </Link>
          </li>
        ))}
      </ul>
    </Panel>
  )
}

function DeliverCard({ api, stats, paths }) {
  return (
    <Panel
      title="Deliver"
      action={<Link href={paths.api_docs} className="text-[13px] font-medium text-base-content/60 transition-colors hover:text-base-content">API docs</Link>}
    >
      <div className="space-y-3 p-4">
        <code className="block w-fit rounded-field bg-base-200 px-2.5 py-1 font-mono text-xs">{api.base_path}/:type</code>
        <div className="space-y-1.5 text-[13px]">
          <div className="flex items-baseline justify-between">
            <span className="text-base-content/60">Content types exposed</span>
            <span className="font-mono text-xs tabular-nums">{stats.content_types}</span>
          </div>
          <div className="flex items-baseline justify-between">
            <span className="text-base-content/60">Active tokens</span>
            <span className="font-mono text-xs tabular-nums">{stats.api_tokens}</span>
          </div>
        </div>
        <Link href={paths.api_tokens} className="inline-flex items-center gap-1 text-[13px] font-medium hover:underline">
          Manage tokens
          <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M5 12h14"/><path d="m12 5 7 7-7 7"/></svg>
        </Link>
      </div>
    </Panel>
  )
}

function Step({ done, href, children }) {
  return (
    <li>
      <Link href={href} className="flex items-center gap-3 rounded-field px-2.5 py-2.5 transition-colors hover:bg-base-200">
        {done ? (
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="var(--color-success)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21.801 10A10 10 0 1 1 17 3.335"/><path d="m9 11 3 3L22 4"/></svg>
        ) : (
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="text-base-content/30"><circle cx="12" cy="12" r="10"/></svg>
        )}
        <span className={`text-[13px] font-medium ${done ? "text-base-content/50 line-through" : ""}`}>{children}</span>
      </Link>
    </li>
  )
}

function GettingStarted({ stats, hasFields, paths, firstType }) {
  return (
    <Panel title="Get started">
      <ul className="p-2">
        <Step done={stats.content_types > 0} href={paths.new_content_type}>Create a content type</Step>
        <Step done={hasFields} href={firstType ? firstType.paths.show : paths.content_types}>Add fields</Step>
        <Step done={stats.entries > 0} href={firstType ? firstType.paths.new_document : paths.content_types}>Write an entry</Step>
        <Step done={stats.api_tokens > 0} href={paths.api_tokens}>Generate an API token</Step>
      </ul>
    </Panel>
  )
}

export default function Show({ stats, has_fields: hasFields, recent_documents: recentDocuments, content_types: contentTypes, api }) {
  const { paths } = usePage().props
  const typesWithEntries = contentTypes.filter((t) => t.entry_count > 0)

  return (
    <>
      <PageHeader title="Dashboard" description="Your content at a glance.">
        <Link href={paths.new_content_type} className="btn">New Content Type</Link>
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

      <div className="grid grid-cols-2 gap-3 md:grid-cols-3 lg:grid-cols-5">
        <StatTile href={paths.content} label="Entries" value={stats.entries} />
        <StatTile href={paths.content_types} label="Content Types" value={stats.content_types} />
        <StatTile href={paths.components} label="Components" value={stats.components} />
        <StatTile href={paths.media} label="Media" value={stats.media_assets} />
        <StatTile href={paths.api_tokens} label="API Tokens" value={stats.api_tokens} />
      </div>

      <div className="mt-4 grid items-start gap-4 lg:grid-cols-3">
        <div className="lg:col-span-2">
          {recentDocuments.length > 0 ? (
            <RecentEntries documents={recentDocuments} />
          ) : (
            <GettingStarted stats={stats} hasFields={hasFields} paths={paths} firstType={contentTypes[0]} />
          )}
        </div>
        <div className="space-y-4">
          {typesWithEntries.length > 0 && <ByType contentTypes={typesWithEntries} />}
          <DeliverCard api={api} stats={stats} paths={paths} />
        </div>
      </div>
    </>
  )
}
