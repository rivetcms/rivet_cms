import { Link, usePage } from "@inertiajs/react"
import Flash from "./Flash"
import ThemeToggle from "./ThemeToggle"

const NAV_ICONS = {
  content: (
    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z" /><path d="M14 2v4a2 2 0 0 0 2 2h4" /><path d="M10 9H8" /><path d="M16 13H8" /><path d="M16 17H8" />
    </svg>
  ),
  contentTypes: (
    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect width="18" height="18" x="3" y="3" rx="2" /><path d="M3 9h18" /><path d="M9 21V9" />
    </svg>
  ),
  components: (
    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="m7.5 4.27 9 5.15" /><path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z" /><path d="m3.3 7 8.7 5 8.7-5" /><path d="M12 22V12" />
    </svg>
  ),
  media: (
    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect width="18" height="18" x="3" y="3" rx="2" ry="2" /><circle cx="9" cy="9" r="2" /><path d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21" />
    </svg>
  ),
}

function NavLink({ href, icon, active, children }) {
  return (
    <li>
      <Link
        href={href}
        className={`flex items-center gap-2.5 rounded-field px-2.5 py-2 text-[13px] font-medium transition-colors ${active ? "bg-primary/10 text-primary" : "text-base-content/70 hover:bg-base-200"}`}
      >
        <span className={active ? "" : "text-base-content/50"}>{icon}</span>
        {children}
      </Link>
    </li>
  )
}

function Aside({ paths, appVersion, url }) {
  const isActive = (path) => url === path || url.startsWith(`${path}/`)

  return (
    <div className="drawer-side z-20 border-r border-base-300 bg-base-100">
      <label htmlFor="sidebar-drawer" aria-label="Close sidebar" className="drawer-overlay"></label>
      <aside className="flex min-h-full w-60 flex-col p-3">
        <Link href={paths.root} className="mb-4 flex items-center gap-2.5 rounded-field px-2 py-2 transition-colors hover:bg-base-200">
          <div className="flex aspect-square size-7 items-center justify-center rounded-field bg-primary text-primary-content">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" className="h-3.5 w-3.5"><rect width="256" height="256" fill="none"></rect><line x1="208" y1="128" x2="128" y2="208" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" strokeWidth="32"></line><line x1="192" y1="40" x2="40" y2="192" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" strokeWidth="32"></line></svg>
          </div>
          <div className="grid flex-1 text-left leading-tight">
            <span className="truncate text-[13px] font-semibold tracking-tight">Rivet CMS</span>
            <span className="truncate font-mono text-[10px] text-base-content/50">v{appVersion}</span>
          </div>
        </Link>

        <div className="px-2.5 pb-1 text-[11px] font-semibold uppercase tracking-wider text-base-content/40">Manage</div>
        <ul className="flex w-full list-none flex-col gap-0.5 p-0">
          <NavLink href={paths.content} icon={NAV_ICONS.content} active={isActive(paths.content)}>
            Content
          </NavLink>
          <NavLink href={paths.content_types} icon={NAV_ICONS.contentTypes} active={isActive(paths.content_types)}>
            Content Types
          </NavLink>
          <NavLink href={paths.components} icon={NAV_ICONS.components} active={isActive(paths.components)}>
            Components
          </NavLink>
          <NavLink href={paths.media} icon={NAV_ICONS.media} active={isActive(paths.media)}>
            Media
          </NavLink>
        </ul>
      </aside>
    </div>
  )
}

function Header() {
  return (
    <header className="navbar sticky top-0 z-10 min-h-12 border-b border-base-300 bg-base-100 px-3 py-0">
      <div className="flex-none lg:hidden">
        <label htmlFor="sidebar-drawer" aria-label="Toggle sidebar" className="btn btn-square btn-ghost btn-sm">
          <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect width="18" height="18" x="3" y="3" rx="2"></rect><path d="M9 3v18"></path></svg>
        </label>
      </div>
      <div className="flex-1"></div>
      <div className="flex-none items-center gap-1">
        <ThemeToggle />
        <div className="dropdown dropdown-end">
          <div tabIndex={0} role="button" className="btn btn-circle btn-ghost btn-sm">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10"/><circle cx="12" cy="10" r="3"/><path d="M7 20.662V19a2 2 0 0 1 2-2h6a2 2 0 0 1 2 2v1.662"/></svg>
          </div>
          <ul tabIndex={0} className="dropdown-content menu z-10 mt-1 w-48 rounded-box border border-base-300 bg-base-100 p-1.5 shadow-lg">
            <li>
              <button type="button" className="gap-2 text-[13px]">
                <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path><polyline points="16 17 21 12 16 7"></polyline><line x1="21" y1="12" x2="9" y2="12"></line></svg>
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
  const { props: { paths, app_version: appVersion }, url } = usePage()

  return (
    <>
      <Flash />
      <div className="drawer lg:drawer-open">
        <input id="sidebar-drawer" type="checkbox" className="drawer-toggle" />
        <div className="drawer-content flex min-h-screen flex-col bg-base-200/50">
          <Header />
          <main className="flex-1 px-4 py-6 lg:px-8">
            <div className="mx-auto w-full max-w-5xl">{children}</div>
          </main>
        </div>
        <Aside paths={paths} appVersion={appVersion} url={url} />
      </div>
    </>
  )
}
