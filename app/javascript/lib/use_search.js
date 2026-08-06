import { useEffect, useRef, useState } from "react"

// Controlled search input state that calls onSearch after the user pauses typing
export function useSearch(initial, onSearch, delay = 250) {
  const [q, setQ] = useState(initial || "")
  const first = useRef(true)

  useEffect(() => {
    if (first.current) {
      first.current = false
      return
    }
    const timer = setTimeout(() => onSearch(q), delay)
    return () => clearTimeout(timer)
  }, [q]) // eslint-disable-line react-hooks/exhaustive-deps

  return [q, setQ]
}
