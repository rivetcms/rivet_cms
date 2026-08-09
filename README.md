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

The media library uses Active Storage. If your app doesn't have it yet,
install it first:

```bash
$ bin/rails active_storage:install
```

Run the migrations (the engine appends its own automatically, alongside
Active Storage's):

```bash
$ bin/rails db:migrate
```

`rivet_cms:install:migrations` is also available if you'd rather copy the
engine's migrations into your app's `db/migrate` than have them run from the
gem; upgrading the gem then means re-running it to pull new migrations.

Visit `/cms` and create your admin account; that's it. The admin UI's
JavaScript and CSS are precompiled into the gem (`app/assets/builds/`) and
served through the asset pipeline (Propshaft or Sprockets), so no frontend
tooling is required in the host app.

## Authentication

Out of the box RivetCMS handles sign-in itself: the first visit creates the
first admin account, and a Users page invites more. CE has no roles, so every
signed-in user can do everything; role and record-scoped permissions are a
RivetCMS Pro feature. New users are invited with a copyable sign-in link
(signed, expires in 3 days, dies once a password is set), so no mail delivery
is required. There is no self-registration, and users are deactivated rather
than deleted.

Apps with their own authentication plug it in instead, which disables all of
the above (no engine login routes, no Users page; manage people in your own
admin):

```ruby
RivetCms.configure do |config|
  config.authenticate = ->(controller) { controller.user_signed_in? }
  config.current_user = ->(controller) { controller.current_user }
  config.login_path   = "/login"
  config.logout_path  = "/logout"
end
```

## Starter content types

RivetCMS ships content-type templates (blog, pages, events, FAQ, team,
testimonials, site settings) so a fresh install isn't a blank slate:

```bash
$ bin/rails rivet_cms:templates                 # list available templates
$ bin/rails rivet_cms:seed                      # load all of them
$ bin/rails rivet_cms:seed TEMPLATES=blog,pages # load a subset
$ bin/rails rivet_cms:seed ORG=example.com      # into a specific org, by domain
```

Templates are a starting point, not a fixture: they create content types,
fields, and components you then edit freely. Loading is idempotent, re-running
updates the same records by slug rather than duplicating them.

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
(entries), `:schema` (content types, fields, components), `:media`, `:api`
(docs and tokens), or `:users` (built-in user management). The default policy
allows everything; installing your own replaces it, and the user it receives
is whatever your `current_user` lambda returns (or the built-in account):

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

The policy also receives the affected record when one applies (`check.record`
is nil otherwise), so per-record decisions are possible; a denied record is
hidden from admin surfaces as well as refused. RivetCMS Pro provides packaged
roles and record-scoped permission management.

This policy governs the admin UI only — the delivery API is token-gated and
media blob URLs are served by Active Storage outside the seam. Minting an
API token additionally requires `:read, :content`, since tokens read content
through the delivery API.

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

Webhook delivery is a single **unsigned** POST: anyone who learns the
endpoint URL can forge it. Treat webhooks as a trigger, not as trusted data;
re-fetch content through the delivery API rather than acting on payload
fields.

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

RivetCMS is licensed under the GNU Lesser General Public License v3.0 or
later (LGPL-3.0-or-later). The full text is in [`COPYING.LESSER`](COPYING.LESSER)
(the additional permissions) and [`COPYING`](COPYING) (the GPLv3 it builds on).

In short: you can use RivetCMS in your own application, including a closed-
source or commercial one, without that application becoming subject to the
LGPL. If you modify RivetCMS itself and distribute that modified version,
those modifications must be shared under the same license.
