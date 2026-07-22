import { useState } from "react"
import EditorDialog from "./EditorDialog"
import { TextInput, ToggleField } from "../forms"

export default function LinkDialog({ initial, onClose, onSubmit, onRemove }) {
  const [href, setHref] = useState(initial.href || "")
  const [title, setTitle] = useState(initial.title || "")
  const [rel, setRel] = useState(initial.rel || "")
  const [newTab, setNewTab] = useState(initial.target === "_blank")

  const submit = () => {
    if (!href.trim()) return
    onSubmit({
      href: href.trim(),
      title: title.trim() || null,
      target: newTab ? "_blank" : null,
      rel: newTab ? [ "noopener", "noreferrer", rel ].filter(Boolean).join(" ") : rel.trim() || null
    })
  }

  return (
    <EditorDialog title="Link" onClose={onClose} onSubmit={submit} submitLabel="Save link">
      <TextInput label="URL" autoFocus placeholder="https://…" value={href} onChange={(e) => setHref(e.target.value)} />
      <TextInput label="Title" hint="Tooltip / accessible name (optional)" value={title} onChange={(e) => setTitle(e.target.value)} />
      <TextInput label="rel" hint="e.g. nofollow, sponsored (optional)" value={rel} onChange={(e) => setRel(e.target.value)} />
      <ToggleField label="Open in new tab" description="Adds target=_blank and rel=noopener noreferrer" checked={newTab} onChange={setNewTab} />
      {initial.href && (
        <button type="button" className="text-[13px] font-medium text-error hover:underline" onClick={onRemove}>
          Remove link
        </button>
      )}
    </EditorDialog>
  )
}
