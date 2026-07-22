import { useState } from "react"
import { router, usePage } from "@inertiajs/react"
import PageHeader from "../../components/PageHeader"
import { TextInput, SelectInput, FormActions } from "../../components/forms"

function NewTokenBanner({ token }) {
  const [copied, setCopied] = useState(false)
  const copy = () => {
    navigator.clipboard?.writeText(token)
    setCopied(true)
    setTimeout(() => setCopied(false), 1500)
  }

  return (
    <div className="mb-5 rounded-box border border-warning/40 bg-warning/10 p-4">
      <div className="text-[13px] font-semibold">Copy your new token now — it won't be shown again.</div>
      <div className="mt-2 flex items-center gap-2">
        <code className="flex-1 truncate rounded-field border border-base-300 bg-base-100 px-3 py-2 font-mono text-[13px]">{token}</code>
        <button type="button" className="btn btn-sm btn-primary" onClick={copy}>{copied ? "Copied" : "Copy"}</button>
      </div>
    </div>
  )
}

export default function Index({ tokens, new_token: newToken }) {
  const tokensPath = usePage().props.paths.api_tokens
  const [name, setName] = useState("")
  const [scope, setScope] = useState("published")

  const create = (e) => {
    e.preventDefault()
    router.post(tokensPath, { name, scope }, { onSuccess: () => setName("") })
  }

  const revoke = (token) => {
    if (confirm(`Revoke "${token.name}"? Any consumer using it will lose access.`)) router.delete(token.paths.destroy)
  }

  return (
    <>
      <PageHeader title="API Tokens" description="Bearer tokens for the delivery API. Preview tokens can also read drafts." />

      {newToken && <NewTokenBanner token={newToken} />}

      <form onSubmit={create} className="mb-6 rounded-box border border-base-300 bg-base-100 p-4">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-end">
          <div className="flex-1">
            <TextInput label="Name" required placeholder="e.g. Marketing site" value={name} onChange={(e) => setName(e.target.value)} />
          </div>
          <div className="w-full sm:w-48">
            <SelectInput label="Scope" value={scope} onChange={(e) => setScope(e.target.value)}>
              <option value="published">Published</option>
              <option value="preview">Preview (reads drafts)</option>
            </SelectInput>
          </div>
          <FormActions>
            <button type="submit" className="btn btn-primary">Create token</button>
          </FormActions>
        </div>
      </form>

      {tokens.length === 0 ? (
        <div className="rounded-box border border-dashed border-base-300 bg-base-100 py-16 text-center text-[13px] text-base-content/50">
          No API tokens yet.
        </div>
      ) : (
        <div className="overflow-x-auto rounded-box border border-base-300 bg-base-100">
          <table className="table">
            <thead>
              <tr className="text-[11px] uppercase tracking-wider text-base-content/50">
                <th>Name</th><th>Scope</th><th>Token</th><th>Last used</th><th className="w-16 text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {tokens.map((token) => (
                <tr key={token.id} className="hover">
                  <td className="font-medium">{token.name}</td>
                  <td>
                    <span className={`badge badge-sm font-medium ${token.scope === "preview" ? "badge-warning badge-soft" : "badge-ghost"}`}>
                      {token.scope}
                    </span>
                  </td>
                  <td><code className="rounded-selector bg-base-200 px-1.5 py-0.5 font-mono text-xs">{token.masked}</code></td>
                  <td className="text-[13px] text-base-content/60">{token.last_used_at ? new Date(token.last_used_at).toLocaleString() : "Never"}</td>
                  <td>
                    <div className="flex justify-end">
                      <button type="button" className="btn btn-ghost btn-sm btn-square text-error" onClick={() => revoke(token)} aria-label={`Revoke ${token.name}`}>
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
