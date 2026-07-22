import { useRef, useState } from "react"
import EditorDialog from "./EditorDialog"
import { TextInput } from "../forms"

function LockIcon({ locked }) {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect width="18" height="11" x="3" y="11" rx="2" ry="2" />
      {locked ? <path d="M7 11V7a5 5 0 0 1 10 0v4" /> : <path d="M7 11V7a5 5 0 0 1 9.9-1" />}
    </svg>
  )
}

export default function ImageDialog({ asset, onClose, onSubmit }) {
  const [alt, setAlt] = useState(asset.filename || "")
  const [width, setWidth] = useState("")
  const [height, setHeight] = useState("")
  const [locked, setLocked] = useState(true)
  const [natural, setNatural] = useState(null)
  const ratio = useRef(null)

  const onImgLoad = (e) => {
    const { naturalWidth, naturalHeight } = e.target
    if (naturalWidth && naturalHeight) {
      ratio.current = naturalWidth / naturalHeight
      setNatural({ w: naturalWidth, h: naturalHeight })
    }
  }

  const changeWidth = (v) => {
    setWidth(v)
    if (!locked || !ratio.current) return
    setHeight(v ? String(Math.round(Number(v) / ratio.current)) : "")
  }

  const changeHeight = (v) => {
    setHeight(v)
    if (!locked || !ratio.current) return
    setWidth(v ? String(Math.round(Number(v) * ratio.current)) : "")
  }

  const submit = () => onSubmit({ src: asset.url, alt: alt.trim(), width: width || null, height: height || null })

  return (
    <EditorDialog title="Insert image" onClose={onClose} onSubmit={submit} submitLabel="Insert">
      {asset.url && (
        <img src={asset.url} alt={alt} onLoad={onImgLoad} className="max-h-40 w-full rounded-field border border-base-300 object-contain" />
      )}
      <TextInput label="Alt text" hint="Describe the image for accessibility" value={alt} onChange={(e) => setAlt(e.target.value)} />
      <div>
        <label className="mb-1.5 flex items-center justify-between text-[13px] font-medium">
          <span>Dimensions <span className="font-normal text-base-content/40">— px, blank for original</span></span>
          {natural && <span className="font-normal text-base-content/50">Original {natural.w} × {natural.h}</span>}
        </label>
        <div className="flex items-center gap-2">
          <input type="number" min="1" placeholder={natural ? String(natural.w) : "Width"} value={width} onChange={(e) => changeWidth(e.target.value)} className="input input-bordered input-sm w-full" />
          <button
            type="button"
            onClick={() => setLocked(!locked)}
            aria-label={locked ? "Unlock aspect ratio" : "Lock aspect ratio"}
            title={locked ? "Aspect ratio locked" : "Aspect ratio unlocked"}
            className={`flex size-8 shrink-0 items-center justify-center rounded-selector border transition-colors ${locked ? "border-primary/40 bg-primary/10 text-primary" : "border-base-300 text-base-content/50 hover:bg-base-200"}`}
          >
            <LockIcon locked={locked} />
          </button>
          <input type="number" min="1" placeholder={natural ? String(natural.h) : "Height"} value={height} onChange={(e) => changeHeight(e.target.value)} className="input input-bordered input-sm w-full" />
        </div>
      </div>
    </EditorDialog>
  )
}
