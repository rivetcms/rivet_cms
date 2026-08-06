import { useEffect, useState } from "react"
import { createPortal } from "react-dom"
import { usePage } from "@inertiajs/react"
import axios from "axios"
import { formatBytes } from "../../lib/format"

function FileGlyph() {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" className="text-base-content/40">
      <path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/><path d="M14 2v4a2 2 0 0 0 2 2h4"/>
    </svg>
  )
}

// The configured allowlist narrowed to the field's kind; falls back to broad
// wildcards when no allowlist is configured. The server validates either way.
function acceptFor(kind, mediaAccept) {
  if (!mediaAccept) return kind === "image" ? "image/*" : kind === "video" ? "video/*" : undefined
  if (kind === "image" || kind === "video") {
    return mediaAccept.split(",").filter((t) => t.startsWith(`${kind}/`)).join(",")
  }
  return mediaAccept
}

export default function MediaPicker({ open, onClose, onSelect, kind }) {
  const { paths, media_accept: mediaAccept } = usePage().props
  const mediaPath = paths.media
  const [assets, setAssets] = useState([])
  const [loading, setLoading] = useState(false)
  const [uploading, setUploading] = useState(false)
  const [error, setError] = useState(null)
  const [q, setQ] = useState("")

  useEffect(() => {
    if (!open) return
    const timer = setTimeout(() => {
      setLoading(true)
      setError(null)
      axios
        .get(mediaPath, { headers: { Accept: "application/json" }, params: q ? { q } : {} })
        .then((res) => setAssets(res.data))
        .catch(() => setError("Could not load the media library"))
        .finally(() => setLoading(false))
    }, q ? 250 : 0)
    return () => clearTimeout(timer)
  }, [open, mediaPath, q])

  if (!open) return null

  const upload = (file) => {
    if (!file) return
    const data = new FormData()
    data.append("file", file)
    setUploading(true)
    setError(null)
    axios
      .post(mediaPath, data)
      .then((res) => {
        onSelect(res.data)
        onClose()
      })
      .catch((err) => setError(err.response?.data?.errors?.join(", ") || "Upload failed"))
      .finally(() => setUploading(false))
  }

  const shown = kind ? assets.filter((a) => a.kind === kind) : assets

  return createPortal(
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div className="flex max-h-[80vh] w-full max-w-3xl flex-col overflow-hidden rounded-box border border-base-300 bg-base-100 shadow-(--shadow-overlay)" onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between border-b border-base-300 px-4 py-3">
          <h2 className="text-sm font-semibold">Media Library</h2>
          <div className="flex items-center gap-2">
            <input
              type="search"
              className="input input-bordered input-sm w-44"
              placeholder="Search…"
              value={q}
              onChange={(e) => setQ(e.target.value)}
            />
            <label className="btn btn-primary btn-sm cursor-pointer">
              {uploading ? "Uploading…" : "Upload"}
              <input type="file" className="hidden" accept={acceptFor(kind, mediaAccept)} onChange={(e) => upload(e.target.files[0])} />
            </label>
            <button type="button" className="btn btn-ghost btn-sm btn-square" onClick={onClose} aria-label="Close">
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
            </button>
          </div>
        </div>
        {error && <p className="border-b border-base-300 bg-error/5 px-4 py-2 text-[13px] text-error">{error}</p>}
        <div className="flex-1 overflow-y-auto p-4">
          {loading ? (
            <p className="py-10 text-center text-[13px] text-base-content/50">Loading…</p>
          ) : shown.length === 0 ? (
            <p className="py-10 text-center text-[13px] text-base-content/50">No media yet. Upload a file to get started.</p>
          ) : (
            <div className="grid grid-cols-3 gap-3 sm:grid-cols-4">
              {shown.map((asset) => (
                <button key={asset.id} type="button" onClick={() => { onSelect(asset); onClose() }} className="group overflow-hidden rounded-field border border-base-300 text-left transition-colors hover:border-primary">
                  <div className="flex aspect-square items-center justify-center bg-base-200">
                    {asset.kind === "image" ? (
                      <img src={asset.url} alt={asset.filename} className="h-full w-full object-cover" />
                    ) : (
                      <FileGlyph />
                    )}
                  </div>
                  <div className="px-2 py-1.5">
                    <div className="truncate text-[11px] text-base-content/70">{asset.filename}</div>
                    <div className="font-mono text-[10px] text-base-content/50">{formatBytes(asset.byte_size)}</div>
                  </div>
                </button>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>,
    document.body
  )
}
