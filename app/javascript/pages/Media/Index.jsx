import { useState } from "react"
import { router, usePage } from "@inertiajs/react"
import axios from "axios"
import PageHeader from "../../components/PageHeader"
import MediaDetails from "../../components/MediaDetails"
import { formatBytes } from "../../lib/format"
import { useSearch } from "../../lib/use_search"

export default function Index({ assets, pagination, q: initialQ }) {
  const { paths, media_accept: mediaAccept } = usePage().props
  const mediaPath = paths.media
  const [uploading, setUploading] = useState(false)
  const [error, setError] = useState(null)
  const [selected, setSelected] = useState(null)
  const [q, setQ] = useSearch(initialQ, (value) =>
    router.get(mediaPath, value ? { q: value } : {}, { preserveState: true, replace: true })
  )

  const upload = (file) => {
    if (!file) return
    const data = new FormData()
    data.append("file", file)
    setUploading(true)
    setError(null)
    axios
      .post(mediaPath, data)
      .then(() => router.reload({ only: ["assets"] }))
      .catch((err) => setError(err.response?.data?.errors?.join(", ") || "Upload failed"))
      .finally(() => setUploading(false))
  }

  const destroy = (asset) => {
    if (confirm(`Delete "${asset.filename}"? This cannot be undone.`)) {
      setSelected(null)
      router.delete(asset.paths.destroy)
    }
  }

  const saved = () => {
    setSelected(null)
    router.reload({ only: ["assets"] })
  }

  return (
    <>
      <PageHeader title="Media" description="Upload once, reuse across any content.">
        <input
          type="search"
          className="input input-bordered w-52"
          placeholder="Search media…"
          value={q}
          onChange={(e) => setQ(e.target.value)}
        />
        <label className="btn btn-primary cursor-pointer">
          {uploading ? "Uploading…" : "Upload"}
          <input type="file" className="hidden" accept={mediaAccept} onChange={(e) => upload(e.target.files[0])} />
        </label>
      </PageHeader>

      {error && <div className="alert alert-error mb-4 px-3 py-2.5 text-[13px]">{error}</div>}

      {assets.length === 0 ? (
        <div className="rounded-box border border-dashed border-base-300 bg-base-100 py-16 text-center text-[13px] text-base-content/50">
          {initialQ ? `No media match "${initialQ}".` : "No media yet. Upload a file to get started."}
        </div>
      ) : (
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-4 lg:grid-cols-5">
          {assets.map((asset) => (
            <div key={asset.id} className="group relative overflow-hidden rounded-box border border-base-300 bg-base-100 transition-colors hover:border-base-content/30">
              <button type="button" onClick={() => setSelected(asset)} className="block w-full cursor-pointer text-left" aria-label={`Details for ${asset.filename}`}>
                <div className="flex aspect-square items-center justify-center bg-base-200">
                  {asset.kind === "image" ? (
                    <img src={asset.url} alt={asset.alt || asset.filename} className="h-full w-full object-cover" />
                  ) : (
                    <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" className="text-base-content/40"><path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/><path d="M14 2v4a2 2 0 0 0 2 2h4"/></svg>
                  )}
                </div>
                <div className="px-2 py-1.5">
                  <div className="truncate text-[11px] text-base-content/70" title={asset.filename}>{asset.filename}</div>
                  <div className="font-mono text-[10px] text-base-content/50">{formatBytes(asset.byte_size)}</div>
                </div>
              </button>
              <button type="button" onClick={() => destroy(asset)} className="absolute right-1.5 top-1.5 flex size-6 items-center justify-center rounded-selector bg-base-100/90 text-base-content/50 opacity-0 shadow-sm transition-opacity hover:text-error group-hover:opacity-100" aria-label={`Delete ${asset.filename}`}>
                <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 6h18"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>
              </button>
            </div>
          ))}
        </div>
      )}

      {selected && <MediaDetails asset={selected} onClose={() => setSelected(null)} onSaved={saved} onDelete={destroy} />}

      {pagination && pagination.total_pages > 1 && (
        <div className="mt-4 flex items-center justify-center gap-2">
          <button
            type="button"
            className="btn btn-ghost btn-sm border border-base-300"
            disabled={pagination.page <= 1}
            onClick={() => router.get(mediaPath, { page: pagination.page - 1, ...(initialQ ? { q: initialQ } : {}) }, { preserveScroll: true })}
          >
            Previous
          </button>
          <span className="text-[13px] text-base-content/60">Page {pagination.page} of {pagination.total_pages}</span>
          <button
            type="button"
            className="btn btn-ghost btn-sm border border-base-300"
            disabled={pagination.page >= pagination.total_pages}
            onClick={() => router.get(mediaPath, { page: pagination.page + 1, ...(initialQ ? { q: initialQ } : {}) }, { preserveScroll: true })}
          >
            Next
          </button>
        </div>
      )}
    </>
  )
}
