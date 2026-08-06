import { useState } from "react"
import SettingsModal from "./SettingsModal"
import { formatBytes } from "../lib/format"
import { useUploadQueue } from "../lib/use_upload_queue"

export function UploadRow({ item, onDismiss }) {
  return (
    <li className="rounded-field border border-base-300 bg-base-100 px-3 py-2">
      <div className="flex items-center gap-2.5">
        <span className="min-w-0 flex-1 truncate text-[13px]">{item.name}</span>
        <span className="shrink-0 font-mono text-[10px] text-base-content/50">{formatBytes(item.size)}</span>
        {item.status === "done" && (
          <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="var(--color-success)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="shrink-0"><path d="M21.801 10A10 10 0 1 1 17 3.335"/><path d="m9 11 3 3L22 4"/></svg>
        )}
        {item.status === "error" && (
          <>
            <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="var(--color-error)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="shrink-0"><circle cx="12" cy="12" r="10"/><path d="m15 9-6 6"/><path d="m9 9 6 6"/></svg>
            {onDismiss && (
              <button type="button" className="flex shrink-0 p-0.5 text-base-content/40 transition-colors hover:text-base-content" onClick={() => onDismiss(item.id)} aria-label={`Dismiss ${item.name}`}>
                <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
              </button>
            )}
          </>
        )}
      </div>
      {item.status === "uploading" && (
        <div className="mt-1.5 h-[3px] w-full bg-base-200">
          <div className="h-full bg-primary transition-all" style={{ width: `${item.progress}%` }} />
        </div>
      )}
      {item.status === "error" && <div className="mt-1 text-[12px] text-error">{item.error}</div>}
    </li>
  )
}

// Shared drop zone: click to browse or drag files in. Stops propagation so a
// drop here never also hits the page-level drop target.
export function UploadDropzone({ accept, onFiles, className = "py-10" }) {
  const [dragging, setDragging] = useState(false)

  const onDrop = (e) => {
    e.preventDefault()
    e.stopPropagation()
    setDragging(false)
    if (e.dataTransfer.files.length) onFiles(e.dataTransfer.files)
  }

  return (
    <label
      className={`flex cursor-pointer flex-col items-center justify-center gap-1.5 rounded-field border border-dashed transition-colors ${className} ${dragging ? "border-primary bg-base-200" : "border-base-300 bg-base-200/40 hover:bg-base-200/70"}`}
      onDragEnter={(e) => e.stopPropagation()}
      onDragOver={(e) => { e.preventDefault(); e.stopPropagation(); setDragging(true) }}
      onDragLeave={() => setDragging(false)}
      onDrop={onDrop}
    >
      <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-base-content/40"><path d="M12 13v8"/><path d="m8 17 4-4 4 4"/><path d="M20.39 18.39A5 5 0 0 0 18 9h-1.26A8 8 0 1 0 3 16.3"/></svg>
      <span className="text-[13px] font-medium">Drag files here or browse</span>
      <span className="text-[11px] text-base-content/50">Uploads start immediately</span>
      <input type="file" className="hidden" multiple accept={accept} onChange={(e) => { onFiles(e.target.files); e.target.value = "" }} />
    </label>
  )
}

export default function MediaUpload({ mediaPath, accept, onClose, onSettled }) {
  const { items, enqueue } = useUploadQueue(mediaPath, onSettled)

  return (
    <SettingsModal open title="Upload media" onClose={onClose}>
      <UploadDropzone accept={accept} onFiles={enqueue} />

      {items.length > 0 && (
        <ul className="mt-4 space-y-1">
          {items.map((item) => (
            <UploadRow key={item.id} item={item} />
          ))}
        </ul>
      )}
    </SettingsModal>
  )
}
