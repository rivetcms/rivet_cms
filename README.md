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
(fields: `user`, `action`, `resource`, `organization`, and a reserved
`record`) and returning a boolean; default allow. `action` is `:read`,
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

Notes: the editor screen is a `:read` surface (mutations are gated
separately); minting an API token additionally requires `:read, :content`
since tokens read content through the delivery API; the dashboard is
reachable by any authenticated user but filters every section through the
same checks. This policy governs the admin UI only — the delivery API is
token-gated and media blob URLs are served by Active Storage outside the
seam.

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
