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

## Deleting content

Deleting is recoverable by default. Removing a content type or an entry moves
it to a trash: it disappears from the admin and stops being served by the
delivery API, but every revision and value is kept, and restoring brings it
all back. Both trashes are reachable from their list pages.

Permanent deletion lives only inside the trash, so removing and destroying are
always two deliberate steps. Purging a content type additionally requires
typing its name, since it destroys every entry of that type; purging a single
entry asks for a plain confirmation naming it.

```ruby
# Restoring is also available from the console
RivetCms::ContentType.with_discarded.find_by(slug: "articles").undiscard!
RivetCms::Document.with_discarded.find_by(slug: "hello-world").undiscard!
```

A trashed type or entry keeps its slug reserved, so restoring can never
collide with something created in the meantime.

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
