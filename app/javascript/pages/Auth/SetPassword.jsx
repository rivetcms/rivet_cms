import { useForm } from "@inertiajs/react"
import AuthCard from "./AuthCard"

export default function SetPassword({ name, submit_path: submitPath }) {
  const form = useForm({ password: "" })
  const submit = (e) => {
    e.preventDefault()
    form.patch(submitPath)
  }

  return (
    <AuthCard title={`Welcome, ${name}`} description="Choose a password to finish setting up your account.">
      <form onSubmit={submit} className="space-y-4">
        <label className="flex flex-col gap-1">
          <span className="text-[11px] font-semibold uppercase tracking-wider text-base-content/50">Password</span>
          <input type="password" className="input input-bordered w-full" autoFocus autoComplete="new-password"
                 value={form.data.password} onChange={(e) => form.setData("password", e.target.value)} />
          <span className="text-[11px] text-base-content/50">At least 8 characters</span>
        </label>
        <button type="submit" className="btn btn-primary w-full" disabled={form.processing}>Set password and sign in</button>
      </form>
    </AuthCard>
  )
}

SetPassword.layout = (page) => page
