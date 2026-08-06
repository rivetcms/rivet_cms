import { useState } from "react"
import axios from "axios"
import SettingsModal from "./SettingsModal"
import { formatBytes } from "../lib/format"
import FileIcon from "./FileIcon"

function MetaRow({ label, children }) {
  return (
    <div className="flex items-baseline justify-between gap-4 text-[13px]">
      <span className="shrink-0 text-base-content/60">{label}</span>
      <span className="truncate font-mono text-xs">{children}</span>
    </div>
  )
}

export default function MediaDetails({ asset, onClose, onSaved, onDelete }) {
  const [form, setForm] = useState({ title: asset.title || "", alt: asset.alt || "", description: asset.description || "" })
  const [saving, setSaving] = useState(false)
  const [copied, setCopied] = useState(false)
  const [error, setError] = useState(null)

  const set = (key) => (e) => setForm({ ...form, [key]: e.target.value })

  const save = (e) => {
    e.preventDefault()
    setSaving(true)
    setError(null)
    axios
      .patch(asset.paths.update, form)
      .then((res) => onSaved(res.data))
      .catch((err) => setError(err.response?.data?.errors?.join(", ") || "Save failed"))
      .finally(() => setSaving(false))
  }

  const copyUrl = () => {
    navigator.clipboard.writeText(new URL(asset.url, window.location.origin).href).then(() => {
      setCopied(true)
      setTimeout(() => setCopied(false), 1500)
    })
  }

  return (
    <SettingsModal open title={asset.filename} onClose={onClose}>
      <div className="grid gap-5 sm:grid-cols-2">
        <div className="flex flex-col gap-3">
          <div className="flex aspect-square items-center justify-center overflow-hidden rounded-field border border-base-300 bg-base-200">
            {asset.kind === "image" ? (
              <img src={asset.url} alt={asset.alt || asset.filename} className="h-full w-full object-contain" />
            ) : asset.thumbnail_url ? (
              <img src={asset.thumbnail_url} alt={asset.alt || asset.filename} className="h-full w-full object-contain" />
            ) : (
              <FileIcon contentType={asset.content_type} kind={asset.kind} size={36} />
            )}
          </div>
          <div className="space-y-1.5 rounded-field bg-base-200/60 p-3">
            <MetaRow label="Type">{asset.content_type}</MetaRow>
            <MetaRow label="Size">{formatBytes(asset.byte_size)}</MetaRow>
            <MetaRow label="Kind">{asset.kind}</MetaRow>
            {asset.created_at && <MetaRow label="Uploaded">{new Date(asset.created_at).toLocaleDateString()}</MetaRow>}
          </div>
          <div className="flex items-center gap-1">
            <a href={asset.url} download={asset.filename} className="btn btn-ghost btn-sm border border-base-300">Download</a>
            <button type="button" className="btn btn-ghost btn-sm border border-base-300" onClick={copyUrl}>
              {copied ? "Copied" : "Copy URL"}
            </button>
            <button type="button" className="btn btn-ghost btn-sm ml-auto text-error" onClick={() => onDelete(asset)}>Delete</button>
          </div>
        </div>

        <form onSubmit={save} className="flex flex-col gap-3">
          <label className="flex flex-col gap-1">
            <span className="text-[11px] font-semibold uppercase tracking-wider text-base-content/50">Title</span>
            <input type="text" className="input input-bordered w-full" value={form.title} onChange={set("title")} />
          </label>
          <label className="flex flex-col gap-1">
            <span className="text-[11px] font-semibold uppercase tracking-wider text-base-content/50">Alt text</span>
            <input type="text" className="input input-bordered w-full" value={form.alt} onChange={set("alt")} />
          </label>
          <label className="flex flex-col gap-1">
            <span className="text-[11px] font-semibold uppercase tracking-wider text-base-content/50">Description</span>
            <textarea className="textarea textarea-bordered w-full" rows={4} value={form.description} onChange={set("description")} />
          </label>
          {error && <p className="text-[13px] text-error">{error}</p>}
          <div className="mt-auto flex justify-end gap-2 pt-2">
            <button type="button" className="btn btn-ghost" onClick={onClose}>Cancel</button>
            <button type="submit" className="btn btn-primary" disabled={saving}>{saving ? "Saving…" : "Save"}</button>
          </div>
        </form>
      </div>
    </SettingsModal>
  )
}
