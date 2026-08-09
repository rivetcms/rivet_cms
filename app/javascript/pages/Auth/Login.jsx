import { useForm } from "@inertiajs/react"
import AuthCard from "./AuthCard"

export default function Login({ submit_path: submitPath }) {
  const form = useForm({ email: "", password: "" })
  const submit = (e) => {
    e.preventDefault()
    form.post(submitPath)
  }

  return (
    <AuthCard title="Sign in">
      <form onSubmit={submit} className="space-y-4">
        <label className="flex flex-col gap-1">
          <span className="text-[11px] font-semibold uppercase tracking-wider text-base-content/50">Email</span>
          <input type="email" className="input input-bordered w-full" autoFocus autoComplete="username"
                 value={form.data.email} onChange={(e) => form.setData("email", e.target.value)} />
        </label>
        <label className="flex flex-col gap-1">
          <span className="text-[11px] font-semibold uppercase tracking-wider text-base-content/50">Password</span>
          <input type="password" className="input input-bordered w-full" autoComplete="current-password"
                 value={form.data.password} onChange={(e) => form.setData("password", e.target.value)} />
        </label>
        <button type="submit" className="btn btn-primary w-full" disabled={form.processing}>Sign in</button>
      </form>
    </AuthCard>
  )
}

Login.layout = (page) => page
