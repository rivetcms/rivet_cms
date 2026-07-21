import { Link, usePage } from "@inertiajs/react"
import PageHeader from "../../components/PageHeader"

function ResourceCard({ href, title, description, icon }) {
  return (
    <Link
      href={href}
      className="group rounded-box border border-base-300 bg-base-100 p-5 transition-all hover:-translate-y-0.5 hover:border-primary/40 hover:shadow-sm"
    >
      <div className="flex items-start justify-between">
        <div className="flex size-9 items-center justify-center rounded-field bg-primary/10 text-primary">
          {icon}
        </div>
        <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-base-content/30 transition-all group-hover:translate-x-0.5 group-hover:text-primary">
          <path d="M5 12h14"/><path d="m12 5 7 7-7 7"/>
        </svg>
      </div>
      <h2 className="mt-4 text-sm font-semibold">{title}</h2>
      <p className="mt-0.5 text-[13px] text-base-content/60">{description}</p>
    </Link>
  )
}

export default function Show() {
  const { paths } = usePage().props

  return (
    <>
      <PageHeader title="Dashboard" description="Manage your content structure and reusable blocks." />

      <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
        <ResourceCard
          href={paths.content_types}
          title="Content Types"
          description="Define the structure of your content"
          icon={
            <svg xmlns="http://www.w3.org/2000/svg" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <rect width="18" height="18" x="3" y="3" rx="2" /><path d="M3 9h18" /><path d="M9 21V9" />
            </svg>
          }
        />
        <ResourceCard
          href={paths.components}
          title="Components"
          description="Reusable content blocks"
          icon={
            <svg xmlns="http://www.w3.org/2000/svg" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="m7.5 4.27 9 5.15" /><path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z" /><path d="m3.3 7 8.7 5 8.7-5" /><path d="M12 22V12" />
            </svg>
          }
        />
      </div>
    </>
  )
}
