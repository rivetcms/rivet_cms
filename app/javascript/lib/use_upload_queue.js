import { useRef, useState } from "react"
import axios from "axios"

let itemId = 0

// Parallel upload queue with per-file progress and result.
// onSettled fires once each time the queue drains, success or not.
export function useUploadQueue(mediaPath, onSettled) {
  const [items, setItems] = useState([])
  const pending = useRef(0)

  const patch = (id, changes) => setItems((prev) => prev.map((item) => (item.id === id ? { ...item, ...changes } : item)))

  const enqueue = (files) => {
    Array.from(files).forEach((file) => {
      const id = itemId++
      pending.current += 1
      setItems((prev) => [...prev, { id, name: file.name, size: file.size, progress: 0, status: "uploading", error: null }])

      const data = new FormData()
      data.append("file", file)
      axios
        .post(mediaPath, data, {
          onUploadProgress: (e) => e.total && patch(id, { progress: Math.round((e.loaded / e.total) * 100) }),
        })
        .then(() => patch(id, { status: "done", progress: 100 }))
        .catch((err) => patch(id, { status: "error", error: err.response?.data?.errors?.join(", ") || "Upload failed" }))
        .finally(() => {
          pending.current -= 1
          if (pending.current === 0) onSettled()
        })
    })
  }

  const dismiss = (id) => setItems((prev) => prev.filter((item) => item.id !== id))
  const clearDone = () => setItems((prev) => prev.filter((item) => item.status !== "done"))

  return { items, enqueue, dismiss, clearDone }
}
