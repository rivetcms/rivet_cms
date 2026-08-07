# RivetCms

RivetCms is a headless CMS Rails engine, similar to Strapi. The admin UI is built
with [Inertia.js](https://inertiajs.com) and React, and ships as a precompiled,
self-contained bundle — host applications do **not** need Node, Yarn, or any
JavaScript build step.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "rivet_cms"
```

And then execute:

```bash
$ bundle
```

Mount the engine in `config/routes.rb`:

```ruby
mount RivetCms::Engine => "/cms"
```

Run the migrations (the engine appends its migrations automatically):

```bash
$ bin/rails db:migrate
```

That's it. The admin UI's JavaScript and CSS are precompiled into the gem
(`app/assets/builds/`) and served through the asset pipeline (Propshaft or
Sprockets), so no frontend tooling is required in the host app.

## Media processing (optional system dependencies)

The media library generates thumbnails through Active Storage. What renders
depends on which system binaries the host has installed; everything degrades
gracefully to a file-type icon when a binary is missing:

| Binary | Install (Debian/Ubuntu) | Install (macOS) | Enables |
|---|---|---|---|
| libvips (recommended) | `apt install libvips` | `brew install vips` | Image thumbnails (resized variants) |
| poppler | `apt install poppler-utils` | `brew install poppler` | PDF thumbnails (first page) |
| ffmpeg | `apt install ffmpeg` | `brew install ffmpeg` | Video thumbnails (first frame) |

None are hard dependencies: uploads, storage, and delivery work without them.
Without poppler or ffmpeg, PDFs and videos show a type icon instead of a
preview. libvips is the one you really want: without it image thumbnail
requests fail and grid cells stay on their neutral placeholder (full-size
originals still serve fine everywhere else). Thumbnails are processed lazily
on first request and cached by Active Storage.

## Reading content from Ruby

Host apps can read CMS content directly — no HTTP round-trip — with the same
semantics and options as the delivery API (published-only lists, draft-leak
rules, constant-query preloading):

```ruby
# Lists: sort, date-range filters, pagination, populate, sparse fields
posts = RivetCms.entries("posts", sort: "-published_at", page: 1, per_page: 10)
posts = RivetCms.entries("posts", populate: %w[author categories])   # or populate: :all
events = RivetCms.entries("events", filters: { "starts_at" => { gte: Date.today } })

# Single entries by slug (nil when missing or unpublished)
post = RivetCms.entry("posts", "hello-world", populate: :all)
post = RivetCms.entry("posts", "hello-world", preview: true)   # draft when present

# Single-type content
settings = RivetCms.single("site-settings")

# Entries expose field values as methods, [] access, or the raw hash
post.title            # data access (post[:title] and post.data also work)
post.author.name      # populated references are nested entries
post.to_h             # same shape as the API JSON
posts.total_pages     # lists carry pagination numbers
```

The organization defaults to `RivetCms::Current.organization` (or the default
organization); pass `organization:` explicitly in jobs and scripts. Unknown
option values — sort/filter/populate/fields keys — raise
`RivetCms::ContentQuery::Error`, mirroring the API's 400s.

## Authorization

Admin access control is a single policy receiving a `RivetCms::AccessCheck`
(fields: `user`, `action`, `resource`, `organization`, and `record`) and
returning a boolean; default allow. `action` is `:read`,
`:write`, `:publish`, or `:delete`; `resource` is a coarse domain: `:content`
(entries), `:schema` (content types, fields, components), `:media`, or `:api`
(docs and tokens). The user is whatever your `current_user` lambda returns:

```ruby
RivetCms.configure do |config|
  # Editors draft content; only admins publish, delete, or touch schema/API
  config.can = lambda do |check|
    next true if check.user&.admin?
    case [ check.action, check.resource ]
    in [ :read, _ ] | [ :write, :content ] | [ :write, :media ] then true
    else false # unknown pairs deny: the vocabulary grows in minor releases
    end
  end
end
```

Write policies to allowlist known pairs and deny everything else; new actions
and resources may appear in minor releases and must fail closed. A raising
policy denies (fail closed) and logs. Denials redirect back with a flash in
the admin UI and return 403 JSON on API-shaped endpoints.

Checks run in two phases. First without a `record`, before anything is
loaded: that check asks whether the action is available to the user *at all*
(it also drives sidebar visibility). Then, once the controller has loaded
the thing being acted on, the same check runs again with `record` set: the
entry, content type (for entry lists and creation, the type they belong to),
field, component, media asset, or API token. A per-record policy must return
true for the recordless phase whenever the user could pass it for at least
one record, and put the real decision in the record phase:

```ruby
config.can = lambda do |check|
  case check.record
  when nil then true                    # phase one: available at all?
  when RivetCms::Document then check.user.can_edit?(check.record)
  else true
  end
end
```

Denials compose downward. Checking `(action, :content, record: content_type)`
means "may the user <action> this type's content": entry actions check the
type as well as the entry (verb-matched), field actions check their owning
type or component, and the API docs suppress schemas, references, and
embedded component structures for anything the schema phase denies. Denying
a parent therefore denies its children even on direct URLs.

List surfaces (entry lists, the cross-type Content page, dashboards,
media/type/component/token lists, trash pages, and the editor's reference
picker) filter every row through the record phase, so a record the policy
hides is not shown anywhere. Two consequences worth knowing: filtering
happens after pagination, so a page can come up short when rows are hidden,
and stat counts are aggregates that are not filtered per record; a policy
hiding individual records still lets their existence be counted.

Notes: the editor screen is a `:read` surface (mutations are gated
separately); minting an API token additionally requires `:read, :content`
since tokens read content through the delivery API; the dashboard is
reachable by any authenticated user but filters every section through the
same checks. This policy governs the admin UI only — the delivery API is
token-gated and media blob URLs are served by Active Storage outside the
seam.

## Deleting content

Deleting is recoverable by default. Removing a content type or an entry moves
it to a trash: it disappears from the admin and stops being served by the
delivery API, but every revision and value is kept, and restoring brings it
all back. Both trashes are reachable from their list pages. Trash and restore
share one gate: whichever `:delete` permission removing something required,
restoring it requires too, since restoring puts content back on the delivery
API.

Permanent deletion lives only inside the trash, so removing and destroying are
always two deliberate steps. Purging a content type additionally requires
typing its name, since it destroys every entry of that type; purging a single
entry asks for a plain confirmation naming it. Purging an entry requires
`:delete` on the content domain; purging a content type requires `:delete` on
both the schema and content domains.

```ruby
# Restoring is also available from the console
RivetCms::ContentType.with_discarded.find_by(slug: "articles").undiscard!
RivetCms::Document.with_discarded.find_by(slug: "hello-world").undiscard!
```

A trashed type or entry keeps its slug reserved, so restoring can never
collide with something created in the meantime.

## Revisions and retention

Publishing snapshots the draft into a new published revision, so a document
always has a working draft plus the revision the delivery API serves. By
default **nothing is ever deleted**: every snapshot is kept. Pruning is
opt-in, because storage you can watch grow is a smaller problem than content
that quietly disappeared:

```ruby
RivetCms.configure do |config|
  config.revision_retention = :all # default: keep every snapshot
  # config.revision_retention = 10 # keep the last 10 superseded snapshots
  # config.revision_retention = 0  # keep only the live snapshot
end
```

Only `:all` or a non-negative integer are accepted; anything else raises at
assignment rather than risking a silent misread (`"all"` is normalized, but a
stray `nil` or `90.days` is rejected because there is no safe interpretation).

The current published revision and the working draft are never pruned, and
pruning is skipped entirely for a document with nothing published. Retention
applies as documents are published, so lowering it takes effect gradually,
one document at a time, rather than sweeping the corpus at once.

Things worth knowing about `:all`: superseded snapshots keep referencing their
media, so the library will refuse to delete an asset that only an old revision
still uses. Draft and archived revisions are never pruned at any setting.

Extensions can subscribe to `:prune` to archive a revision before it is
destroyed, and can override `RivetCms.retention_for(document)` to vary
retention per organization or content type:

```ruby
RivetCms.on(:prune, key: :cold_storage) do |revision|
  # Read what you need here and now: the row is destroyed the moment this
  # returns, so a background job handed only the id would find nothing.
  ColdStorage.put(revision.id, revision.content_values.map(&:attributes))
end
```

Two caveats this hook cannot paper over. It runs inside the publish
transaction, so a rolled-back publish leaves any external write (S3, an HTTP
call) describing a publish that never happened. And a subscriber that raises
is logged and swallowed, exactly like the other lifecycle hooks, so the
revision is still destroyed. If you need archive-or-abort semantics, set
`revision_retention = :all` and prune out of band instead.

Keeping history is what a revision-history and rollback UI builds on;
`RivetCms::DocumentRevision.restore_owned_into(snapshot, draft)` is the
rollback primitive (it replaces the draft's values rather than merging into
them). RivetCMS Pro ships the history UI on top of these.

## Lifecycle hooks and webhooks

Run host code when content changes. Hooks fire after the database commit and
receive the published snapshot revision; a failing hook is logged, never
raised into the publish path:

```ruby
RivetCms.on(:publish) do |revision|
  Rails.cache.delete("navigation")
  BuildSiteJob.perform_later
end
```

Register hooks in an initializer. If you must register from reloadable code
(`to_prepare`), pass a `key:` — re-registering the same key replaces the
handler instead of stacking a duplicate on every reload:

```ruby
RivetCms.on(:publish, key: :sitemap) { |revision| RefreshSitemapJob.perform_later }
```

For HTTP consumers, configure webhook endpoints instead; each matching event
POSTs a JSON payload (event name, document id, slug, content type,
organization, locale, published_at, author) through ActiveJob:

```ruby
RivetCms.configure do |config|
  config.webhooks = [
    { url: "https://example.com/deploy-hook", events: %w[entry.published] }
  ]
end
```

Omitting `events` subscribes an endpoint to everything. Malformed webhook
config raises at boot. Delivery failures (connection errors and non-2xx
responses alike) raise inside the job, so retries follow your queue adapter's
defaults. Current events: `entry.published`.

CE delivery is a single **unsigned** POST: anyone who learns the endpoint URL
can forge it. Treat webhooks as a trigger, not as trusted data; re-fetch
content through the delivery API rather than acting on payload fields. Signed
deliveries with managed retries are part of RivetCMS Pro.

## Extending the admin

An engine (or the host app) can add sidebar items and admin pages. Nav items
register server-side; the sidebar is computed per request and filtered
through the authorization policy, so an item a user cannot reach is never
rendered, core items included:

```ruby
RivetCms.register_nav :audit_log,
  label: "Audit Log",
  section: "Manage",                 # existing section, or a new one
  icon: :content,                    # built-in icon name; unknown names get a dot
  requires: [:read, :content],       # can? gate, nil means always visible
  path: -> { audit_log_path },       # instance_exec'd in the controller, or a string
  position: 80                       # items sort by position across sections
```

Always use a lambda for routes inside the admin: it resolves through the
route helpers per request, so links follow the host's mount point
(`/cms`, `/back-office`, ...). String paths are emitted verbatim and are only
right for external URLs.

Pages are React components served by the extension's own controllers
(`render inertia: "AuditLog/Index"`). The extension ships a precompiled
bundle, registered so the layout loads it after the core bundle:

```ruby
RivetCms.register_admin_script "my_extension"      # and register_admin_stylesheet
```

```js
// my_extension.js: runs before the admin app boots. Mark react, react-dom
// and @inertiajs/react as externals and use the shared instances, so there
// is exactly one React in the page.
const { React, Inertia } = window.RivetCMS
window.RivetCMS.registerPages({ "AuditLog/Index": AuditLogIndex })
```

Extensions can also mount components inside core pages at named slots.
Components render in registration order, receive the listed props, and a
component that throws is logged and dropped without taking the page down:

```js
window.RivetCMS.registerSlot("entry.actions", ScheduleButton)
```

Current slots, all in the entry editor and only rendered for saved entries,
each receiving `{ document, contentType }`:

| Slot | Where |
|---|---|
| `entry.status` | next to the Draft/Published badge |
| `entry.actions` | header buttons, before Delete and Publish |
| `entry.panels` | below the entry form |

Registration is reload-safe: re-registering a nav key replaces the item, and
asset names are deduplicated. A registered bundle that cannot be resolved is
logged and skipped rather than failing the admin, so check the log if an
extension's assets are not loading.

A complete working example lives in `spec/pro_stub`: a second engine that
adds an admin route, page, nav item, hook subscriptions, and assets through
these seams. Its specs (`spec/requests/rivet_cms/pro_stub_engine_spec.rb`)
exercise every seam end to end from the extension's side.

## Development

The frontend lives in `app/javascript` (React + Inertia pages) and is bundled
with esbuild; styles are Tailwind CSS 4 + daisyUI. To work on the engine:

```bash
$ yarn install
$ bin/dev        # runs the dummy app plus JS/CSS watchers
```

Rebuild the production bundles (committed to the repo so the gem stays
self-contained):

```bash
$ yarn build && yarn build:css
```

Run the test suite:

```bash
$ bundle exec rspec
```

## Contributing

Contribution directions go here.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
