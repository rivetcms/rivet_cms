import { useEffect, useRef, useState } from "react"
import { EditorView } from "@codemirror/view"
import { EditorState } from "@codemirror/state"
import { basicSetup } from "codemirror"
import { markdown } from "@codemirror/lang-markdown"
import { marked } from "marked"

const cmTheme = EditorView.theme({
  "&": { fontSize: "13px", backgroundColor: "transparent", minHeight: "10rem" },
  ".cm-scroller": { minHeight: "10rem" },
  "&.cm-focused": { outline: "none" },
  ".cm-content": { fontFamily: "var(--font-mono)", padding: "10px 12px" },
  ".cm-gutters": { backgroundColor: "transparent", border: "none", color: "color-mix(in oklab, var(--color-base-content) 35%, transparent)" },
  ".cm-activeLine": { backgroundColor: "color-mix(in oklab, var(--color-base-content) 4%, transparent)" },
  ".cm-activeLineGutter": { backgroundColor: "transparent" },
})

function TabBtn({ active, onClick, children }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`rounded-selector px-2 py-1 text-[12px] font-medium transition-colors ${active ? "bg-primary/10 text-primary" : "text-base-content/60 hover:bg-base-200"}`}
    >
      {children}
    </button>
  )
}

export default function MarkdownEditor({ value, onChange }) {
  const [tab, setTab] = useState("write")
  const host = useRef(null)
  const onChangeRef = useRef(onChange)
  onChangeRef.current = onChange

  useEffect(() => {
    if (tab !== "write" || !host.current) return

    const view = new EditorView({
      parent: host.current,
      state: EditorState.create({
        doc: value || "",
        extensions: [
          basicSetup,
          markdown(),
          EditorView.lineWrapping,
          cmTheme,
          EditorView.updateListener.of((update) => {
            if (update.docChanged) onChangeRef.current(update.state.doc.toString())
          }),
        ],
      }),
    })

    return () => view.destroy()
    // Re-created only when toggling tabs; seeded from the latest value each time.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tab])

  return (
    <div className="overflow-hidden rounded-field border border-base-300 bg-base-100 focus-within:border-primary focus-within:shadow-[0_0_0_1px_var(--color-primary)]">
      <div className="flex items-center gap-1 border-b border-base-300 px-1.5 py-1">
        <TabBtn active={tab === "write"} onClick={() => setTab("write")}>Write</TabBtn>
        <TabBtn active={tab === "preview"} onClick={() => setTab("preview")}>Preview</TabBtn>
        <span className="ml-auto pr-1 font-mono text-[10px] uppercase tracking-wider text-base-content/40">Markdown</span>
      </div>
      {tab === "write" ? (
        <div ref={host} className="min-h-40" />
      ) : (
        <div
          className="rivet-prose min-h-40 px-3 py-2.5 text-[13px]"
          dangerouslySetInnerHTML={{ __html: marked.parse(value?.trim() ? value : "_Nothing to preview_") }}
        />
      )}
    </div>
  )
}
