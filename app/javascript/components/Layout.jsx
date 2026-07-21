import { Link, usePage } from "@inertiajs/react"
import Flash from "./Flash"
import ThemeToggle from "./ThemeToggle"

function NavIcon() {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="m7 11 2-2-2-2" />
      <path d="M11 13h4" />
      <rect width="18" height="18" x="3" y="3" rx="2" ry="2" />
    </svg>
  )
}

function Aside({ paths, appVersion }) {
  return (
    <div className="drawer-side z-20 bg-base-100 border-r border-base-300">
      <label htmlFor="sidebar-drawer" aria-label="Close sidebar" className="drawer-overlay"></label>
      <aside className="min-h-full w-64 p-4">
        <div className="mb-6">
          <Link href={paths.root} className="flex items-center gap-3 px-2 py-3">
            <div className="bg-primary text-primary-content flex aspect-square size-8 items-center justify-center rounded-lg">
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" className="h-4 w-4"><rect width="256" height="256" fill="none"></rect><line x1="208" y1="128" x2="128" y2="208" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" strokeWidth="32"></line><line x1="192" y1="40" x2="40" y2="192" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" strokeWidth="32"></line></svg>
            </div>
            <div className="grid flex-1 text-left text-sm leading-tight">
              <span className="truncate font-medium">Rivet CMS</span>
              <span className="truncate text-xs opacity-60">v{appVersion}</span>
            </div>
          </Link>
        </div>
        <ul className="menu menu-md gap-4 w-full">
          <li>
            <a href="#">
              <NavIcon />
              Content
            </a>
          </li>
          <li>
            <Link href={paths.content_types}>
              <NavIcon />
              Content Types
            </Link>
          </li>
          <li>
            <Link href={paths.components}>
              <NavIcon />
              Components
            </Link>
          </li>
        </ul>
      </aside>
    </div>
  )
}

function Header() {
  return (
    <header className="navbar bg-base-100 sticky top-0 z-10 border-b border-base-300">
      <div className="flex-none lg:hidden">
        <label htmlFor="sidebar-drawer" aria-label="Toggle sidebar" className="btn btn-square btn-ghost">
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect width="18" height="18" x="3" y="3" rx="2"></rect><path d="M9 3v18"></path></svg>
        </label>
      </div>
      <div className="flex-1"></div>
      <div className="flex-none gap-2">
        <ThemeToggle />
        <div className="dropdown dropdown-end">
          <div tabIndex={0} role="button" className="btn btn-ghost btn-circle">
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10"/><circle cx="12" cy="10" r="3"/><path d="M7 20.662V19a2 2 0 0 1 2-2h6a2 2 0 0 1 2 2v1.662"/></svg>
          </div>
          <ul tabIndex={0} className="dropdown-content menu bg-base-100 rounded-box z-10 w-52 p-2 shadow">
            <li>
              <button type="button" className="flex items-center gap-2">
                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path><polyline points="16 17 21 12 16 7"></polyline><line x1="21" y1="12" x2="9" y2="12"></line></svg>
                Log out
              </button>
            </li>
          </ul>
        </div>
      </div>
    </header>
  )
}

export default function Layout({ children }) {
  const { paths, app_version: appVersion } = usePage().props

  return (
    <>
      <Flash />
      <div className="drawer lg:drawer-open">
        <input id="sidebar-drawer" type="checkbox" className="drawer-toggle" />
        <div className="drawer-content flex flex-col">
          <Header />
          <main className="py-8 px-4">{children}</main>
        </div>
        <Aside paths={paths} appVersion={appVersion} />
      </div>
    </>
  )
}
