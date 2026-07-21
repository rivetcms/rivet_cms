import { useMemo, useRef, useState } from "react"
import axios from "axios"

// Searchable category picker that can also create a category inline
export default function CategoryCombobox({ categories: initialCategories, value, onChange, createPath }) {
  const [categories, setCategories] = useState(initialCategories)
  const [search, setSearch] = useState("")
  const [creating, setCreating] = useState(false)
  const [createError, setCreateError] = useState(null)
  const triggerRef = useRef(null)

  const selected = categories.find((c) => c.id === value)

  const filtered = useMemo(() => {
    const term = search.trim().toLowerCase()
    if (!term) return categories
    return categories.filter((c) => c.name.toLowerCase().includes(term))
  }, [categories, search])

  const closeDropdown = () => {
    // daisyUI dropdowns close when focus leaves them
    document.activeElement?.blur()
  }

  const select = (category) => {
    onChange(category.id)
    closeDropdown()
  }

  const createCategory = async () => {
    const name = search.trim()
    if (!name) {
      setCreateError("Enter a name to create a category")
      return
    }

    setCreating(true)
    setCreateError(null)
    try {
      const { data } = await axios.post(createPath, { category: { name } })
      setCategories((prev) => [...prev, data].sort((a, b) => a.name.localeCompare(b.name)))
      onChange(data.id)
      setSearch("")
      closeDropdown()
    } catch (error) {
      setCreateError(error.response?.data?.errors?.join(", ") || "Failed to create category")
    } finally {
      setCreating(false)
    }
  }

  return (
    <div className="dropdown w-full">
      <div ref={triggerRef} tabIndex={0} role="button" className="btn btn-outline justify-between w-full font-normal">
        <span className="truncate">{selected?.name || "Select a category"}</span>
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="opacity-50">
          <path d="m7 15 5 5 5-5" />
          <path d="m7 9 5-5 5 5" />
        </svg>
      </div>
      <div tabIndex={0} className="dropdown-content bg-base-100 rounded-box z-10 w-full p-2 shadow-lg mt-1">
        <div className="form-control mb-2">
          <input
            type="text"
            placeholder="Search or create category..."
            className="input input-bordered input-sm w-full"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
        <ul className="menu menu-sm w-full">
          {filtered.map((category) => (
            <li key={category.id}>
              <button type="button" onClick={() => select(category)} className={category.id === value ? "active" : ""}>
                {category.name}
              </button>
            </li>
          ))}
          {filtered.length === 0 && (
            <li className="menu-title"><span>No matching categories</span></li>
          )}
          <li className="menu-title mt-2"><span>Or create new</span></li>
          <li>
            <button type="button" onClick={createCategory} disabled={creating} className="text-primary">
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <circle cx="12" cy="12" r="10" />
                <path d="M8 12h8" />
                <path d="M12 8v8" />
              </svg>
              {creating ? "Creating..." : search.trim() ? `Create "${search.trim()}"` : "Create category"}
            </button>
          </li>
          {createError && (
            <li className="menu-title text-error"><span>{createError}</span></li>
          )}
        </ul>
      </div>
    </div>
  )
}
