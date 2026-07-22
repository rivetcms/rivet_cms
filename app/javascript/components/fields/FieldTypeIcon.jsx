const ICONS = {
  string: { className: "text-emerald-600", paths: <><path d="M4 7V4h16v3"/><path d="M9 20h6"/><path d="M12 4v16"/></> },
  text: { className: "text-emerald-600", paths: <><path d="M17 6H3"/><path d="M21 12H8"/><path d="M21 18H8"/><path d="M3 12v6"/></> },
  rich_text: { className: "text-violet-600", paths: <><path d="M12 3H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.375 2.625a1 1 0 0 1 3 3l-9.013 9.014a2 2 0 0 1-.853.505l-2.873.84a.5.5 0 0 1-.62-.62l.84-2.873a2 2 0 0 1 .506-.852z"/></> },
  markdown: { className: "text-violet-600", paths: <><path d="M2 4v16h20V4H2z"/><path d="M6 9v6"/><path d="M6 12h3l2-3v6"/><path d="M18 9l-3 3 3 3"/><path d="M15 12h3"/></> },
  integer: { className: "text-blue-600", paths: <><path d="M5 10V7c0-1.1.9-2 2-2h1"/><path d="M9 12h6"/><path d="M19 12h-1"/><path d="M14 7h1c1.1 0 2 .9 2 2v1"/><path d="M5 14v3c0 1.1.9 2 2 2h1"/><path d="M14 19h1c1.1 0 2-.9 2-2v-1"/></> },
  decimal: { className: "text-blue-600", paths: <><circle cx="5" cy="18" r="1"/><path d="M9 14v-3a2.5 2.5 0 0 1 5 0v3a2.5 2.5 0 0 1-5 0Z"/><path d="M17 14v-3a2.5 2.5 0 0 1 5 0v3a2.5 2.5 0 0 1-5 0Z"/></> },
  enumeration: { className: "text-teal-600", paths: <><path d="M8 6h13"/><path d="M8 12h13"/><path d="M8 18h13"/><path d="m3 5 1 1 2-2"/><path d="m3 11 1 1 2-2"/><path d="m3 17 1 1 2-2"/></> },
  boolean: { className: "text-amber-600", paths: <><rect width="14" height="8" x="5" y="8" rx="4"/><circle cx="15" cy="12" r="2"/></> },
  image: { className: "text-pink-600", paths: <><rect width="18" height="18" x="3" y="3" rx="2" ry="2"/><circle cx="9" cy="9" r="2"/><path d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21"/></> },
  video: { className: "text-pink-600", paths: <><path d="m16 13 5.223 3.482a.5.5 0 0 0 .777-.416V7.87a.5.5 0 0 0-.752-.432L16 10.5"/><rect x="2" y="6" width="14" height="12" rx="2"/></> },
  file: { className: "text-slate-600", paths: <><path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/><path d="M14 2v4a2 2 0 0 0 2 2h4"/></> },
  reference: { className: "text-cyan-600", paths: <><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></> },
  component: { className: "text-orange-600", paths: <><path d="m7.5 4.27 9 5.15"/><path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z"/><path d="m3.3 7 8.7 5 8.7-5"/><path d="M12 22V12"/></> },
  date: { className: "text-rose-600", paths: <><path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/></> },
  datetime: { className: "text-rose-600", paths: <><path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/><circle cx="12" cy="16" r="3"/><path d="M12 15v1l.75.75"/></> },
}

const FALLBACK = { className: "text-base-content/40", paths: <rect width="18" height="18" x="3" y="3" rx="2"/> }

export default function FieldTypeIcon({ fieldType, size = 16 }) {
  const icon = ICONS[fieldType] || FALLBACK

  return (
    <svg xmlns="http://www.w3.org/2000/svg" width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className={`shrink-0 ${icon.className}`}>
      {icon.paths}
    </svg>
  )
}
