import { useEffect, useRef, useState } from "react"
import { useEditor, EditorContent } from "@tiptap/react"
import StarterKit from "@tiptap/starter-kit"
import Image from "@tiptap/extension-image"
import Link from "@tiptap/extension-link"
import TextAlign from "@tiptap/extension-text-align"
import MediaPicker from "./MediaPicker"
import LinkDialog from "./LinkDialog"
import ImageDialog from "./ImageDialog"

const IMAGE_ALIGN_STYLE = {
  left: "float:left;margin:0 1rem 0.5rem 0",
  right: "float:right;margin:0 0 0.5rem 1rem",
  center: "display:block;margin-left:auto;margin-right:auto"
}

const CustomLink = Link.extend({
  addAttributes() {
    return { ...this.parent?.(), title: { default: null } }
  }
}).configure({ openOnClick: false })

const dimensionAttribute = (name) => ({
  default: null,
  parseHTML: (el) => el.getAttribute(name),
  renderHTML: (attrs) => (attrs[name] ? { [name]: attrs[name] } : {})
})

const ResizableImage = Image.extend({
  addAttributes() {
    return {
      ...this.parent?.(),
      width: dimensionAttribute("width"),
      height: dimensionAttribute("height"),
      align: {
        default: null,
        parseHTML: (el) => (el.style.float || (el.style.marginLeft === "auto" ? "center" : null)),
        renderHTML: (attrs) => (attrs.align ? { style: IMAGE_ALIGN_STYLE[attrs.align] } : {})
      }
    }
  }
})

function Btn({ active, onClick, label, children }) {
  return (
    <button
      type="button"
      onMouseDown={(e) => e.preventDefault()}
      onClick={onClick}
      aria-label={label}
      title={label}
      className={`flex h-7 min-w-7 items-center justify-center rounded-selector px-1.5 text-[13px] transition-colors ${active ? "bg-primary/10 text-primary" : "text-base-content/60 hover:bg-base-200"}`}
    >
      {children}
    </button>
  )
}

const Divider = () => <span className="mx-0.5 h-4 w-px bg-base-300" />

export default function RichTextEditor({ value, onChange }) {
  const onChangeRef = useRef(onChange)
  onChangeRef.current = onChange
  const [pickerOpen, setPickerOpen] = useState(false)
  const [pendingImage, setPendingImage] = useState(null)
  const [linkOpen, setLinkOpen] = useState(false)
  const [maximized, setMaximized] = useState(false)

  useEffect(() => {
    if (!maximized) return
    const onKey = (e) => e.key === "Escape" && setMaximized(false)
    window.addEventListener("keydown", onKey)
    return () => window.removeEventListener("keydown", onKey)
  }, [maximized])

  const editor = useEditor({
    extensions: [
      StarterKit.configure({ link: false }),
      CustomLink,
      ResizableImage,
      TextAlign.configure({ types: ["heading", "paragraph"] })
    ],
    content: value || "",
    immediatelyRender: false,
    editorProps: {
      attributes: { class: "rivet-prose min-h-40 px-3 py-2.5 text-[13px] focus:outline-none" },
    },
    onUpdate: ({ editor }) => onChangeRef.current(editor.getHTML()),
  })

  if (!editor) return null

  const heading = (level) => editor.chain().focus().toggleHeading({ level }).run()

  const align = (value) => {
    if (editor.isActive("image")) {
      editor.chain().focus().updateAttributes("image", { align: value }).run()
    } else {
      editor.chain().focus().setTextAlign(value).run()
    }
  }

  const alignActive = (value) => (
    editor.isActive("image") ? editor.getAttributes("image").align === value : editor.isActive({ textAlign: value })
  )

  const applyLink = ({ href, title, target, rel }) => {
    editor.chain().focus().extendMarkRange("link").setLink({ href, title, target, rel }).run()
    setLinkOpen(false)
  }

  const removeLink = () => {
    editor.chain().focus().extendMarkRange("link").unsetLink().run()
    setLinkOpen(false)
  }

  const insertImage = ({ src, alt, width, height }) => {
    editor.chain().focus().setImage({ src, alt, width, height }).run()
    setPendingImage(null)
  }

  return (
    <div className={maximized
      ? "fixed inset-0 z-40 flex flex-col bg-base-100"
      : "overflow-hidden rounded-field border border-base-300 bg-base-100 focus-within:border-primary"}>
      <div className="flex flex-wrap items-center gap-0.5 border-b border-base-300 px-1.5 py-1">
        <Btn active={editor.isActive("bold")} onClick={() => editor.chain().focus().toggleBold().run()} label="Bold"><b>B</b></Btn>
        <Btn active={editor.isActive("italic")} onClick={() => editor.chain().focus().toggleItalic().run()} label="Italic"><i>I</i></Btn>
        <Btn active={editor.isActive("underline")} onClick={() => editor.chain().focus().toggleUnderline().run()} label="Underline"><u>U</u></Btn>
        <Btn active={editor.isActive("strike")} onClick={() => editor.chain().focus().toggleStrike().run()} label="Strikethrough"><s>S</s></Btn>
        <Btn active={editor.isActive("code")} onClick={() => editor.chain().focus().toggleCode().run()} label="Inline code">{"<>"}</Btn>
        <Divider />
        <Btn active={editor.isActive("heading", { level: 1 })} onClick={() => heading(1)} label="Heading 1">H1</Btn>
        <Btn active={editor.isActive("heading", { level: 2 })} onClick={() => heading(2)} label="Heading 2">H2</Btn>
        <Btn active={editor.isActive("heading", { level: 3 })} onClick={() => heading(3)} label="Heading 3">H3</Btn>
        <Divider />
        <Btn active={editor.isActive("bulletList")} onClick={() => editor.chain().focus().toggleBulletList().run()} label="Bullet list">•</Btn>
        <Btn active={editor.isActive("orderedList")} onClick={() => editor.chain().focus().toggleOrderedList().run()} label="Numbered list">1.</Btn>
        <Btn active={editor.isActive("blockquote")} onClick={() => editor.chain().focus().toggleBlockquote().run()} label="Quote">❝</Btn>
        <Btn active={editor.isActive("codeBlock")} onClick={() => editor.chain().focus().toggleCodeBlock().run()} label="Code block">{"{ }"}</Btn>
        <Btn onClick={() => editor.chain().focus().setHorizontalRule().run()} label="Divider">―</Btn>
        <Divider />
        <Btn active={alignActive("left")} onClick={() => align("left")} label="Align left">
          <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="21" x2="3" y1="6" y2="6"/><line x1="15" x2="3" y1="12" y2="12"/><line x1="17" x2="3" y1="18" y2="18"/></svg>
        </Btn>
        <Btn active={alignActive("center")} onClick={() => align("center")} label="Align center">
          <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="21" x2="3" y1="6" y2="6"/><line x1="17" x2="7" y1="12" y2="12"/><line x1="19" x2="5" y1="18" y2="18"/></svg>
        </Btn>
        <Btn active={alignActive("right")} onClick={() => align("right")} label="Align right">
          <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="21" x2="3" y1="6" y2="6"/><line x1="21" x2="9" y1="12" y2="12"/><line x1="21" x2="7" y1="18" y2="18"/></svg>
        </Btn>
        <Divider />
        <Btn active={editor.isActive("link")} onClick={() => setLinkOpen(true)} label="Link">
          <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 17H7A5 5 0 0 1 7 7h2"/><path d="M15 7h2a5 5 0 1 1 0 10h-2"/><line x1="8" x2="16" y1="12" y2="12"/></svg>
        </Btn>
        <Btn onClick={() => setPickerOpen(true)} label="Image">
          <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect width="18" height="18" x="3" y="3" rx="2" ry="2"/><circle cx="9" cy="9" r="2"/><path d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21"/></svg>
        </Btn>
        <Divider />
        <Btn onClick={() => editor.chain().focus().undo().run()} label="Undo">↺</Btn>
        <Btn onClick={() => editor.chain().focus().redo().run()} label="Redo">↻</Btn>
        <div className="ml-auto pl-1">
          <Btn active={maximized} onClick={() => setMaximized((v) => !v)} label={maximized ? "Exit full screen (Esc)" : "Full screen"}>
            {maximized ? (
              <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M8 3v3a2 2 0 0 1-2 2H3"/><path d="M21 8h-3a2 2 0 0 1-2-2V3"/><path d="M3 16h3a2 2 0 0 1 2 2v3"/><path d="M16 21v-3a2 2 0 0 1 2-2h3"/></svg>
            ) : (
              <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M8 3H5a2 2 0 0 0-2 2v3"/><path d="M21 8V5a2 2 0 0 0-2-2h-3"/><path d="M3 16v3a2 2 0 0 0 2 2h3"/><path d="M16 21h3a2 2 0 0 0 2-2v-3"/></svg>
            )}
          </Btn>
        </div>
      </div>
      <div className={maximized ? "flex-1 overflow-y-auto" : ""}>
        <EditorContent editor={editor} />
      </div>

      <MediaPicker open={pickerOpen} onClose={() => setPickerOpen(false)} onSelect={setPendingImage} kind="image" />
      {pendingImage && <ImageDialog asset={pendingImage} onClose={() => setPendingImage(null)} onSubmit={insertImage} />}
      {linkOpen && <LinkDialog initial={editor.getAttributes("link")} onClose={() => setLinkOpen(false)} onSubmit={applyLink} onRemove={removeLink} />}
    </div>
  )
}
