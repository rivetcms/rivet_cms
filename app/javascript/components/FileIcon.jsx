const FILE_BODY = (
  <>
    <path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z" />
    <path d="M14 2v4a2 2 0 0 0 2 2h4" />
  </>
)

function glyphFor(contentType, kind) {
  if (contentType === "application/pdf" || contentType?.startsWith("text/")) {
    return <>{FILE_BODY}<path d="M10 9H8" /><path d="M16 13H8" /><path d="M16 17H8" /></>
  }
  if (contentType?.includes("spreadsheet") || contentType === "text/csv" || contentType?.includes("ms-excel")) {
    return <>{FILE_BODY}<path d="M8 13h2" /><path d="M14 13h2" /><path d="M8 17h2" /><path d="M14 17h2" /></>
  }
  if (contentType === "application/zip") {
    return <>{FILE_BODY}<path d="M10 7V6" /><path d="M10 12v-1" /><path d="M10 18v-2" /></>
  }
  if (kind === "video") {
    return <><path d="m16 13 5.223 3.482a.5.5 0 0 0 .777-.416V7.87a.5.5 0 0 0-.752-.432L16 10.5" /><rect x="2" y="6" width="14" height="12" rx="2" /></>
  }
  if (contentType?.startsWith("audio/")) {
    return <><path d="M9 18V5l12-2v13" /><circle cx="6" cy="18" r="3" /><circle cx="18" cy="16" r="3" /></>
  }
  return FILE_BODY
}

// Type-aware fallback glyph for media without a thumbnail representation
export default function FileIcon({ contentType, kind, size = 28 }) {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" className="text-base-content/40">
      {glyphFor(contentType, kind)}
    </svg>
  )
}
