import { useEffect } from "react"
import { Link, usePage } from "@inertiajs/react"
import Flash from "./Flash"
import ThemeToggle from "./ThemeToggle"
import { ConfirmProvider } from "../lib/confirm"

const NAV_ICONS = {
  dashboard: (
    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect width="7" height="9" x="3" y="3" rx="1" /><rect width="7" height="5" x="14" y="3" rx="1" /><rect width="7" height="9" x="14" y="12" rx="1" /><rect width="7" height="5" x="3" y="16" rx="1" />
    </svg>
  ),
  content: (
    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z" /><path d="M14 2v4a2 2 0 0 0 2 2h4" /><path d="M10 9H8" /><path d="M16 13H8" /><path d="M16 17H8" />
    </svg>
  ),
  content_types: (
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
  trash: (
    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 6h18" /><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6" /><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2" /><line x1="10" x2="10" y1="11" y2="17" /><line x1="14" x2="14" y1="11" y2="17" />
    </svg>
  ),
  api: (
    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="m18 16 4-4-4-4" /><path d="m6 8-4 4 4 4" /><path d="m14.5 4-5 16" />
    </svg>
  ),
  api_tokens: (
    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="m15.5 7.5 2.3 2.3a1 1 0 0 0 1.4 0l2.1-2.1a1 1 0 0 0 0-1.4L21 4.9" /><path d="m21 2-9.6 9.6" /><circle cx="7.5" cy="15.5" r="5.5" />
    </svg>
  ),
}

// Items registered without a known icon get a neutral dot
const DEFAULT_ICON = (
  <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <circle cx="12" cy="12" r="3" />
  </svg>
)

function NavLink({ href, icon, active, badge, children }) {
  return (
    <li>
      <Link
        href={href}
        className={`flex items-center gap-2.5 rounded-field px-2.5 py-2 text-[13px] font-medium transition-colors ${active ? "bg-primary text-primary-content" : "text-base-content/70 hover:bg-base-200 hover:text-base-content"}`}
      >
        <span className={active ? "" : "text-base-content/50"}>{icon}</span>
        {children}
        {badge > 0 && (
          <span className={`badge badge-sm ml-auto font-mono tabular-nums ${active ? "badge-outline" : "badge-ghost"}`}>{badge}</span>
        )}
      </Link>
    </li>
  )
}

function UserMenu({ auth, paths }) {
  const initial = (auth?.name || auth?.email || "?").charAt(0).toUpperCase()

  return (
    <div className="dropdown dropdown-top min-w-0 flex-1">
      <div tabIndex={0} role="button" className="flex w-full cursor-pointer items-center gap-2.5 rounded-field px-2 py-1.5 transition-colors hover:bg-base-200">
        <div className="flex size-7 shrink-0 items-center justify-center rounded-field bg-base-200 text-[12px] font-semibold">{initial}</div>
        <div className="min-w-0 flex-1 text-left leading-tight">
          {auth?.name && <div className="truncate text-[13px] font-medium">{auth.name}</div>}
          {auth?.email && auth.email !== auth.name && <div className="truncate text-[11px] text-base-content/50">{auth.email}</div>}
        </div>
      </div>
      {paths.logout && (
        <div tabIndex={0} className="dropdown-content z-30 mb-1 w-52 rounded-box border border-base-300 bg-base-100 p-1.5 shadow-(--shadow-raised)">
          <LogoutForm path={paths.logout} method={paths.logout_method} />
        </div>
      )}
    </div>
  )
}

function Aside({ nav, paths, auth, appVersion, url }) {
  // exact items (the dashboard at root) would otherwise match every subpath
  const isActive = (item) =>
    item.exact
      ? url.replace(/\/$/, "") === item.path.replace(/\/$/, "")
      : url === item.path || url.startsWith(`${item.path}/`)

  return (
    <div className="drawer-side z-20 border-r border-base-300 bg-base-100">
      <label htmlFor="sidebar-drawer" aria-label="Close sidebar" className="drawer-overlay"></label>
      <aside className="flex min-h-full w-60 flex-col p-3">
        <div className="mb-4 flex items-center gap-2.5 px-2 py-2">
          <div className="flex aspect-square size-7 items-center justify-center rounded-field bg-(--orange-5) text-[15px] font-bold text-white">R</div>
          <div className="grid flex-1 text-left leading-tight">
            <span className="truncate text-[14px] font-bold tracking-tight">RivetCMS</span>
            <span className="truncate font-mono text-[10px] text-base-content/50">v{appVersion}</span>
          </div>
        </div>

        {(nav || []).map((group, index) => (
          <div key={group.section || index}>
            {group.section && (
              <div className="mt-4 px-2.5 pb-1 text-[11px] font-semibold uppercase tracking-wider text-base-content/40">{group.section}</div>
            )}
            <ul className="flex w-full list-none flex-col gap-0.5 p-0">
              {group.items.map((item) => (
                <NavLink key={item.key} href={item.path} icon={NAV_ICONS[item.icon] || DEFAULT_ICON} active={isActive(item)} badge={item.badge}>
                  {item.label}
                </NavLink>
              ))}
            </ul>
          </div>
        ))}

        <div className="mt-auto flex items-center gap-1 border-t border-base-200 pt-2">
          {auth || paths.logout ? <UserMenu auth={auth} paths={paths} /> : <div className="flex-1" />}
          <ThemeToggle />
        </div>
      </aside>
    </div>
  )
}

function readCookie(name) {
  const match = document.cookie.split("; ").find((row) => row.startsWith(`${name}=`))
  return match ? decodeURIComponent(match.split("=")[1]) : ""
}

// Logout targets a host route (often DELETE), so submit a real HTML form with
// _method and the CSRF token rather than an Inertia visit.
function LogoutForm({ path, method }) {
  return (
    <form action={path} method="post">
      <input type="hidden" name="_method" value={method || "delete"} />
      <input type="hidden" name="authenticity_token" value={readCookie("XSRF-TOKEN")} />
      <button type="submit" className="flex w-full items-center gap-2 rounded-field px-2.5 py-1.5 text-[13px] transition-colors hover:bg-base-200">
        <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path><polyline points="16 17 21 12 16 7"></polyline><line x1="21" y1="12" x2="9" y2="12"></line></svg>
        Log out
      </button>
    </form>
  )
}

// Desktop has no top bar; this exists only to hold the drawer toggle on mobile
function MobileBar() {
  return (
    <header className="navbar sticky top-0 z-10 min-h-12 border-b border-base-300 bg-base-100 px-3 py-0 lg:hidden">
      <label htmlFor="sidebar-drawer" aria-label="Toggle sidebar" className="btn btn-square btn-ghost btn-sm">
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect width="18" height="18" x="3" y="3" rx="2"></rect><path d="M9 3v18"></path></svg>
      </label>
    </header>
  )
}

export default function Layout({ children }) {
  const { props: { nav, paths, auth, app_version: appVersion }, url } = usePage()

  // Read by the axios 401 interceptor for session-expiry redirects
  useEffect(() => {
    window.__rivetLoginPath = paths.login || null
  }, [paths.login])

  return (
    <ConfirmProvider>
      <Flash />
      <div className="drawer lg:drawer-open">
        <input id="sidebar-drawer" type="checkbox" className="drawer-toggle" />
        <div className="drawer-content flex min-h-screen flex-col bg-base-200/50">
          <MobileBar />
          <main className="flex-1 px-4 py-6 lg:px-8">
            <div className="mx-auto w-full max-w-5xl">{children}</div>
          </main>
        </div>
        <Aside nav={nav} paths={paths} auth={auth} appVersion={appVersion} url={url} />
      </div>
    </ConfirmProvider>
  )
}
