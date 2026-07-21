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
