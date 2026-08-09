import { useState } from "react"
import { router, useForm } from "@inertiajs/react"
import PageHeader from "../../components/PageHeader"
import SettingsModal from "../../components/SettingsModal"
import { timeAgo } from "../../lib/format"
import { useConfirm } from "../../lib/confirm"

const STATUS_BADGES = {
  active: "badge-success badge-soft",
  pending: "badge-warning badge-soft",
  inactive: "badge-ghost",
}

function Field({ label, children }) {
  return (
    <label className="flex flex-col gap-1">
      <span className="text-[11px] font-semibold uppercase tracking-wider text-base-content/50">{label}</span>
      {children}
    </label>
  )
}

function UserFormModal({ title, initial, submitLabel, onSubmit, onClose }) {
  const form = useForm(initial)
  const submit = (e) => {
    e.preventDefault()
    onSubmit(form)
  }

  return (
    <SettingsModal open title={title} onClose={onClose}>
      <form onSubmit={submit} className="space-y-4">
        <Field label="Name">
          <input type="text" className="input input-bordered w-full" autoFocus
                 value={form.data.name} onChange={(e) => form.setData("name", e.target.value)} />
        </Field>
        <Field label="Email">
          <input type="email" className="input input-bordered w-full"
                 value={form.data.email} onChange={(e) => form.setData("email", e.target.value)} />
        </Field>
        <div className="flex justify-end gap-2 pt-2">
          <button type="button" className="btn btn-ghost" onClick={onClose}>Cancel</button>
          <button type="submit" className="btn btn-primary" disabled={form.processing}>{submitLabel}</button>
        </div>
      </form>
    </SettingsModal>
  )
}

// The link is shown exactly once; copying is the whole point of the modal
function InviteLinkModal({ link, onClose }) {
  const [copied, setCopied] = useState(false)
  const copy = async () => {
    await navigator.clipboard.writeText(link)
    setCopied(true)
  }

  return (
    <SettingsModal open title="Sign-in link" onClose={onClose}>
      <div className="space-y-4">
        <p className="text-[13px] text-base-content/70">
          Share this link with them however you like. It expires in 3 days, works once, and will not be shown again.
        </p>
        <div className="flex items-center gap-2">
          <input type="text" readOnly className="input input-bordered w-full font-mono text-xs" value={link}
                 onFocus={(e) => e.target.select()} />
          <button type="button" className="btn btn-primary shrink-0" onClick={copy}>{copied ? "Copied" : "Copy"}</button>
        </div>
      </div>
    </SettingsModal>
  )
}

export default function Index({ users, invite_link: inviteLink }) {
  const confirm = useConfirm()
  const [creating, setCreating] = useState(false)
  const [editing, setEditing] = useState(null)
  // Derived from the prop, not initial state: the page is already mounted
  // when the redirect delivers a fresh link, and useState initials only
  // apply on first mount
  const [dismissedLink, setDismissedLink] = useState(null)
  const link = inviteLink && inviteLink !== dismissedLink ? inviteLink : null

  const deactivate = async (user) => {
    const ok = await confirm({
      title: `Deactivate ${user.name}?`,
      message: "They will no longer be able to sign in. You can reactivate them at any time.",
      confirmLabel: "Deactivate",
      danger: true,
    })
    if (ok) router.patch(user.paths.deactivate)
  }

  const resetLink = async (user) => {
    const ok = await confirm({
      title: `New sign-in link for ${user.name}?`,
      message: "They can use it to set a new password.",
      confirmLabel: "Generate link",
    })
    if (ok) router.post(user.paths.reset_link)
  }

  return (
    <>
      <PageHeader title="Users" description="Everyone who can sign in to the admin.">
        <button type="button" className="btn btn-primary" onClick={() => setCreating(true)}>New User</button>
      </PageHeader>

      <div className="overflow-x-auto rounded-box border border-base-300 bg-base-100">
        <table className="table">
          <thead>
            <tr className="text-[11px] uppercase tracking-wider text-base-content/50">
              <th>Name</th>
              <th>Status</th>
              <th>Added</th>
              <th className="w-56 text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {users.map((user) => (
              <tr key={user.id} className="hover">
                <td>
                  <span className="block font-medium">{user.name}{user.yourself && <span className="ml-1.5 text-[11px] text-base-content/50">(you)</span>}</span>
                  <span className="block font-mono text-[11px] text-base-content/50">{user.email}</span>
                </td>
                <td>
                  <span className={`badge badge-sm font-medium capitalize ${STATUS_BADGES[user.status]}`}>{user.status}</span>
                </td>
                <td className="text-[13px] text-base-content/50">{timeAgo(user.created_at)}</td>
                <td>
                  <div className="flex justify-end gap-1">
                    <button type="button" className="btn btn-ghost btn-sm border border-base-300" onClick={() => setEditing(user)}>Edit</button>
                    {user.status !== "inactive" && (
                      <button type="button" className="btn btn-ghost btn-sm border border-base-300" onClick={() => resetLink(user)}>Sign-in link</button>
                    )}
                    {user.status === "inactive" ? (
                      <button type="button" className="btn btn-ghost btn-sm border border-base-300" onClick={() => router.patch(user.paths.reactivate)}>Reactivate</button>
                    ) : (
                      !user.yourself && (
                        <button type="button" className="btn btn-ghost btn-sm text-error" onClick={() => deactivate(user)}>Deactivate</button>
                      )
                    )}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {creating && (
        <UserFormModal
          title="New user"
          initial={{ name: "", email: "" }}
          submitLabel="Create and get link"
          onSubmit={(form) => form.post(window.location.pathname, { onSuccess: () => setCreating(false) })}
          onClose={() => setCreating(false)}
        />
      )}

      {editing && (
        <UserFormModal
          title={`Edit ${editing.name}`}
          initial={{ name: editing.name, email: editing.email }}
          submitLabel="Save"
          onSubmit={(form) => form.patch(editing.paths.update, { onSuccess: () => setEditing(null) })}
          onClose={() => setEditing(null)}
        />
      )}

      {link && <InviteLinkModal link={link} onClose={() => setDismissedLink(link)} />}
    </>
  )
}
