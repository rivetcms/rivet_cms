import { useEffect, useState } from "react"

const STORAGE_KEY = "rivetTheme"

function currentTheme() {
  return document.documentElement.getAttribute("data-theme") === "dark" ? "dark" : "light"
}

export default function ThemeToggle() {
  const [dark, setDark] = useState(() => currentTheme() === "dark")

  useEffect(() => {
    document.documentElement.setAttribute("data-theme", dark ? "dark" : "lofi")
    try {
      localStorage.setItem(STORAGE_KEY, dark ? "dark" : "light")
    } catch (_) {}
  }, [dark])

  return (
    <label className="btn btn-ghost btn-square btn-sm swap swap-rotate">
      <input type="checkbox" checked={dark} onChange={(e) => setDark(e.target.checked)} />
      {/* light mode shows the moon (what clicking switches to), dark shows the sun */}
      <svg className="swap-off" width="16" height="16" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z"></path></svg>
      <svg className="swap-on" width="16" height="16" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="4"></circle><path d="M12 2v2"></path><path d="M12 20v2"></path><path d="m4.93 4.93 1.41 1.41"></path><path d="m17.66 17.66 1.41 1.41"></path><path d="M2 12h2"></path><path d="M20 12h2"></path><path d="m6.34 17.66-1.41 1.41"></path><path d="m19.07 4.93-1.41 1.41"></path></svg>
    </label>
  )
}
