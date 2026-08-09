import { useForm } from "@inertiajs/react"
import AuthCard from "./AuthCard"

export default function Setup({ submit_path: submitPath, requires_code: requiresCode }) {
  const form = useForm({ name: "", email: "", password: "", setup_code: "" })
  const submit = (e) => {
    e.preventDefault()
    form.post(submitPath)
  }

  return (
    <AuthCard title="Create your admin account" description="You're the first one here. This account owns the CMS.">
      <form onSubmit={submit} className="space-y-4">
        {requiresCode && (
          <label className="flex flex-col gap-1">
            <span className="text-[11px] font-semibold uppercase tracking-wider text-base-content/50">Setup code</span>
            <input type="text" className="input input-bordered w-full font-mono" autoComplete="off"
                   value={form.data.setup_code} onChange={(e) => form.setData("setup_code", e.target.value)} />
            <span className="text-[11px] text-base-content/50">Printed in the server log when this page loads</span>
          </label>
        )}
        <label className="flex flex-col gap-1">
          <span className="text-[11px] font-semibold uppercase tracking-wider text-base-content/50">Name</span>
          <input type="text" className="input input-bordered w-full" autoFocus autoComplete="name"
                 value={form.data.name} onChange={(e) => form.setData("name", e.target.value)} />
        </label>
        <label className="flex flex-col gap-1">
          <span className="text-[11px] font-semibold uppercase tracking-wider text-base-content/50">Email</span>
          <input type="email" className="input input-bordered w-full" autoComplete="username"
                 value={form.data.email} onChange={(e) => form.setData("email", e.target.value)} />
        </label>
        <label className="flex flex-col gap-1">
          <span className="text-[11px] font-semibold uppercase tracking-wider text-base-content/50">Password</span>
          <input type="password" className="input input-bordered w-full" autoComplete="new-password"
                 value={form.data.password} onChange={(e) => form.setData("password", e.target.value)} />
          <span className="text-[11px] text-base-content/50">At least 8 characters</span>
        </label>
        <button type="submit" className="btn btn-primary w-full" disabled={form.processing}>Create account</button>
      </form>
    </AuthCard>
  )
}

Setup.layout = (page) => page
