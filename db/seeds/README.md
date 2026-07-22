# Content-type templates

Reusable schema you can load into an organization as a starting point — content
types, fields, components, and categories, ready to fill with content. They are
**schema only** (no sample entries), and applied **idempotently**: loading a
template again upserts fields rather than duplicating them, so it is safe to
re-run in production.

## Available templates

| Template        | Adds                                                                     |
|-----------------|--------------------------------------------------------------------------|
| `blog`          | Blog Post, Author, Category content types + an SEO component             |
| `pages`         | Page content type + Hero, Call to Action, and SEO components             |
| `site_settings` | Site Settings (single type) + a Social Link component                    |
| `faq`           | FAQ content type                                                         |
| `team`          | Team Member content type                                                 |
| `events`        | Event content type (uses the date/time field types)                     |
| `testimonials`  | Testimonial content type                                                 |

## Usage

From the host app:

```bash
# Everything, into the default organization
bin/rails rivet_cms:seed

# Specific templates
bin/rails rivet_cms:seed TEMPLATES=blog,pages

# A specific organization (by domain)
bin/rails rivet_cms:seed ORG=example.com

# List what's available
bin/rails rivet_cms:templates
```

Or from Ruby (e.g. in the host's `db/seeds.rb`):

```ruby
require "rivet_cms/seeds"

org = RivetCms::Organization.find_by!(domain: "example.com")
RivetCms::Seeds.load!(organization: org, only: %w[blog pages])
```

## Adding your own

Drop a file in `db/seeds/templates/`. Half-width fields declared next to each
other are paired onto the same form row.

```ruby
RivetCms::Seeds.template "products" do
  category "Commerce", system: true

  component "Price", category: "Commerce", slug: "price" do
    integer :amount_cents, width: :half
    string  :currency,     width: :half
  end

  content_type "Product", slug: "products", description: "Things you sell" do
    string    :name, required: true
    rich_text :description
    image     :photo
    component :price, use: "Price", max_items: 1
    reference :related, to: "products"   # omit max_items for a many-relation
  end
end
```
