import { useRef, useState } from "react"
import { router, usePage } from "@inertiajs/react"
import PageHeader from "../../components/PageHeader"
import MediaDetails from "../../components/MediaDetails"
import MediaUpload, { UploadDropzone, UploadRow } from "../../components/MediaUpload"
import Thumbnail from "../../components/Thumbnail"
import { formatBytes } from "../../lib/format"
import { useSearch } from "../../lib/use_search"
import { useUploadQueue } from "../../lib/use_upload_queue"

function CopyUrlButton({ asset }) {
  const [copied, setCopied] = useState(false)

  const copy = () => {
    navigator.clipboard.writeText(new URL(asset.url, window.location.origin).href).then(() => {
      setCopied(true)
      setTimeout(() => setCopied(false), 1200)
    })
  }

  return (
    <button
      type="button"
      onClick={copy}
      className={`flex size-6 items-center justify-center rounded-selector bg-base-100/90 shadow-sm transition-opacity ${copied ? "text-success opacity-100" : "text-base-content/50 opacity-0 hover:text-base-content group-hover:opacity-100"}`}
      aria-label={`Copy URL for ${asset.filename}`}
    >
      {copied ? (
        <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M20 6 9 17l-5-5"/></svg>
      ) : (
        <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect width="14" height="14" x="8" y="8" rx="2" ry="2"/><path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2"/></svg>
      )}
    </button>
  )
}

export default function Index({ assets, pagination, q: initialQ }) {
  const { paths, media_accept: mediaAccept } = usePage().props
  const mediaPath = paths.media
  const [selected, setSelected] = useState(null)
  const [uploadOpen, setUploadOpen] = useState(false)
  const [dragActive, setDragActive] = useState(false)
  const dragDepth = useRef(0)
  const [q, setQ] = useSearch(initialQ, (value) =>
    router.get(mediaPath, value ? { q: value } : {}, { preserveState: true, replace: true })
  )

  // Direct drops upload inline; the modal is the button path
  const dropQueue = useUploadQueue(mediaPath, () => {
    router.reload({ only: ["assets", "pagination"] })
    dropQueue.clearDone()
  })

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

  // Dropping files anywhere on the page uploads them in place. Disabled while
  // a modal is open so there is only ever one drop target on screen.
  const pageDroppable = !uploadOpen && !selected
  const hasFiles = (e) => Array.from(e.dataTransfer.types).includes("Files")
  const onDragEnter = (e) => {
    if (!pageDroppable || !hasFiles(e)) return
    e.preventDefault()
    dragDepth.current += 1
    setDragActive(true)
  }
  const onDragLeave = () => {
    dragDepth.current = Math.max(0, dragDepth.current - 1)
    if (dragDepth.current === 0) setDragActive(false)
  }
  const onDrop = (e) => {
    if (!pageDroppable || !hasFiles(e)) return
    e.preventDefault()
    dragDepth.current = 0
    setDragActive(false)
    if (e.dataTransfer.files.length) dropQueue.enqueue(e.dataTransfer.files)
  }

  return (
    <div
      className="relative min-h-[70vh]"
      onDragEnter={onDragEnter}
      onDragOver={(e) => pageDroppable && hasFiles(e) && e.preventDefault()}
      onDragLeave={onDragLeave}
      onDrop={onDrop}
    >
      <PageHeader title="Media" description="Upload once, reuse across any content.">
        <button type="button" className="btn btn-primary" onClick={() => { setDragActive(false); dragDepth.current = 0; setUploadOpen(true) }}>Upload</button>
      </PageHeader>

      {(assets.length > 0 || initialQ) && (
        <div className="mb-4">
          <input
            type="search"
            className="input input-bordered w-64"
            placeholder="Search media…"
            value={q}
            onChange={(e) => setQ(e.target.value)}
          />
        </div>
      )}

      {dropQueue.items.length > 0 && (
        <ul className="mb-4 space-y-1">
          {dropQueue.items.map((item) => (
            <UploadRow key={item.id} item={item} onDismiss={dropQueue.dismiss} />
          ))}
        </ul>
      )}

      {assets.length === 0 ? (
        initialQ ? (
          <div className="rounded-box border border-dashed border-base-300 bg-base-100 py-16 text-center text-[13px] text-base-content/50">
            No media match "{initialQ}".
          </div>
        ) : (
          <UploadDropzone accept={mediaAccept} onFiles={dropQueue.enqueue} className="py-20" />
        )
      ) : (
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-4 lg:grid-cols-5">
          {assets.map((asset) => (
            <div key={asset.id} className="group relative overflow-hidden rounded-box border border-base-300 bg-base-100 transition-colors hover:border-base-content/30">
              <button type="button" onClick={() => setSelected(asset)} className="block w-full cursor-pointer text-left" aria-label={`Details for ${asset.filename}`}>
                <div className="flex aspect-square items-center justify-center bg-base-200">
                  {asset.kind === "image" ? (
                    <Thumbnail src={asset.thumbnail_url || asset.url} alt={asset.alt || asset.filename} className="h-full w-full object-cover" />
                  ) : (
                    <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" className="text-base-content/40"><path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/><path d="M14 2v4a2 2 0 0 0 2 2h4"/></svg>
                  )}
                </div>
                <div className="px-2 py-1.5">
                  <div className="truncate text-[11px] text-base-content/70" title={asset.filename}>{asset.filename}</div>
                  <div className="font-mono text-[10px] text-base-content/50">{formatBytes(asset.byte_size)}</div>
                </div>
              </button>
              <div className="absolute right-1.5 top-1.5 flex gap-1">
                <CopyUrlButton asset={asset} />
                <button type="button" onClick={() => destroy(asset)} className="flex size-6 items-center justify-center rounded-selector bg-base-100/90 text-base-content/50 opacity-0 shadow-sm transition-opacity hover:text-error group-hover:opacity-100" aria-label={`Delete ${asset.filename}`}>
                  <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 6h18"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {dragActive && (
        <div className="pointer-events-none absolute inset-0 z-40 flex items-center justify-center rounded-box border-2 border-dashed border-primary bg-base-100/85">
          <span className="text-sm font-semibold">Drop to upload</span>
        </div>
      )}

      {uploadOpen && (
        <MediaUpload
          mediaPath={mediaPath}
          accept={mediaAccept}
          onClose={() => setUploadOpen(false)}
          onSettled={() => router.reload({ only: ["assets", "pagination"] })}
        />
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
    </div>
  )
}
