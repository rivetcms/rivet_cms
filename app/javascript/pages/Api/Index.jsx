import { Link } from "@inertiajs/react"
import PageHeader from "../../components/PageHeader"

function Endpoint({ method, path }) {
  return (
    <div className="flex items-center gap-2 rounded-field border border-base-300 bg-base-200/40 px-2.5 py-1.5">
      <span className="rounded-selector bg-primary/10 px-1.5 py-0.5 font-mono text-[11px] font-semibold text-primary">{method}</span>
      <code className="truncate font-mono text-[13px]">{path}</code>
    </div>
  )
}

export default function Index({ base_url: baseUrl, public_api: publicApi, content_types: contentTypes, doc_paths: docPaths }) {
  return (
    <>
      <PageHeader title="API" description="Your read-only content delivery API.">
        <a href={docPaths.openapi} className="btn btn-ghost gap-1.5 border border-base-300 bg-base-100">
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" x2="12" y1="15" y2="3"/></svg>
          Download OpenAPI
        </a>
      </PageHeader>

      <div className="mb-6 rounded-box border border-base-300 bg-base-100 p-5">
        <h2 className="text-sm font-semibold">Authentication</h2>
        <p className="mt-1 text-[13px] text-base-content/60">
          Send an API token as a bearer header on every request.
          {publicApi
            ? " Anonymous reads of published content are currently allowed; a token is still required to read drafts (preview)."
            : " A token is required for all requests."}
        </p>
        <pre className="mt-3 overflow-x-auto rounded-field bg-base-200 px-3 py-2 font-mono text-xs">Authorization: Bearer &lt;your-token&gt;</pre>
        <Link href={docPaths.tokens} className="mt-3 inline-block text-[13px] font-medium text-primary hover:underline">Manage API tokens →</Link>
      </div>

      <div className="mb-4 rounded-box border border-base-300 bg-base-100 p-5">
        <h2 className="text-sm font-semibold">List query parameters</h2>
        <ul className="mt-2 space-y-1 text-[13px] text-base-content/70">
          <li><code className="font-mono">page</code>, <code className="font-mono">per_page</code> — pagination (max 100). Responses wrap items in <code className="font-mono">{`{ data, meta }`}</code>.</li>
          <li><code className="font-mono">sort</code> — e.g. <code className="font-mono">-published_at</code>, <code className="font-mono">slug</code>, or a date field key (prefix <code className="font-mono">-</code> for descending).</li>
          <li><code className="font-mono">{`<dateField>[gte]`}</code> / <code className="font-mono">{`<dateField>[lte]`}</code> — range-filter a date or datetime field.</li>
          <li><code className="font-mono">preview=true</code> — on a single document, returns the draft (requires a preview token).</li>
        </ul>
      </div>

      {contentTypes.length === 0 ? (
        <div className="rounded-box border border-dashed border-base-300 bg-base-100 py-16 text-center text-[13px] text-base-content/50">
          Create a content type to see its endpoints here.
        </div>
      ) : (
        <div className="space-y-4">
          {contentTypes.map((ct) => (
            <div key={ct.slug} className="rounded-box border border-base-300 bg-base-100 p-5">
              <div className="mb-3 flex items-center gap-2">
                <h3 className="text-[15px] font-semibold">{ct.name}</h3>
                <span className={`badge badge-sm font-medium ${ct.single ? "badge-warning badge-soft" : "badge-info badge-soft"}`}>{ct.single ? "Single" : "Collection"}</span>
              </div>

              <div className="space-y-1.5">
                <Endpoint method="GET" path={`${baseUrl}/${ct.slug}`} />
                <Endpoint method="GET" path={`${baseUrl}/${ct.slug}/{slug}`} />
              </div>

              {ct.fields.length > 0 && (
                <div className="mt-4">
                  <div className="mb-1.5 text-[11px] font-semibold uppercase tracking-wider text-base-content/40">Response fields</div>
                  <div className="flex flex-wrap gap-1.5">
                    {ct.fields.map((f) => (
                      <span key={f.key} className="rounded-selector border border-base-300 bg-base-200/50 px-1.5 py-0.5 font-mono text-[11px]">
                        {f.key}<span className="text-base-content/40">: {f.type}</span>{f.required && <span className="text-error">*</span>}
                      </span>
                    ))}
                  </div>
                </div>
              )}

              <details className="mt-4">
                <summary className="cursor-pointer text-[13px] font-medium text-base-content/60 hover:text-base-content">Sample request</summary>
                <pre className="mt-2 overflow-x-auto rounded-field bg-base-200 px-3 py-2 font-mono text-xs">{`curl -H "Authorization: Bearer <token>" \\\n  "${baseUrl}/${ct.slug}?per_page=10"`}</pre>
              </details>
            </div>
          ))}
        </div>
      )}
    </>
  )
}
