import { useState } from "react"
import { router } from "@inertiajs/react"
import SettingsModal from "./SettingsModal"

// Typing the name is the only guard between a trashed type and real deletion,
// so the dialog states exactly what dies before it will enable the button.
export default function PurgeDialog({ contentType, onClose }) {
  const [typed, setTyped] = useState("")
  const entries = contentType.documents_count

  return (
    <SettingsModal open title={`Permanently delete ${contentType.name}?`} onClose={onClose}>
      <div className="space-y-4">
        <p className="text-[13px] text-base-content/70">
          This permanently deletes <span className="font-medium text-base-content">{contentType.name}</span>
          {entries !== undefined && <> and its <span className="font-medium text-base-content">{entries}</span> {entries === 1 ? "entry" : "entries"}</>}
          , including every revision. This cannot be undone.
        </p>
        <label className="flex flex-col gap-1">
          <span className="text-[11px] font-semibold uppercase tracking-wider text-base-content/50">
            Type <span className="font-mono normal-case">{contentType.name}</span> to confirm
          </span>
          <input type="text" className="input input-bordered w-full" value={typed} onChange={(e) => setTyped(e.target.value)} autoFocus />
        </label>
        <div className="flex justify-end gap-2 pt-2">
          <button type="button" className="btn btn-ghost" onClick={onClose}>Cancel</button>
          <button
            type="button"
            className="btn btn-error"
            disabled={typed.trim() !== contentType.name}
            onClick={() => router.delete(contentType.paths.purge, { data: { confirm: typed.trim() } })}
          >
            Delete permanently
          </button>
        </div>
      </div>
    </SettingsModal>
  )
}
