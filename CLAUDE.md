# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

RivetCMS is a headless CMS Rails engine (similar to Strapi) designed to be mounted into existing Rails applications. It provides multi-tenant content management with flexible content types, fields, and components.

## Development Commands

```bash
# Install dependencies
bundle install
yarn install

# Database setup (uses dummy app in spec/dummy for development)
cd spec/dummy && bundle exec rails db:create db:migrate

# Run development server with hot reloading
bundle exec foreman start -f Procfile.dev

# Run tests
bundle exec rspec                    # All tests
bundle exec rspec spec/models/       # Model specs only
bundle exec rspec spec/path/to/spec.rb:42  # Single test at line

# Linting
bundle exec rubocop
bundle exec rubocop -a               # Auto-fix

# Build assets manually
yarn build                           # JavaScript
yarn build:css                       # Tailwind CSS
```

## Architecture

### Multi-Tenancy
All resources are scoped to `Organization` using `acts_as_tenant`. The tenant is set in `ApplicationController` based on request host. During development, a default "Development Org" is auto-created.

### Core Data Model

```
Organization (tenant)
├── User (has_secure_password, roles: member/admin/owner)
├── ContentType (schema definition)
│   ├── Field (schema columns with layout: row/position/width)
│   └── Content (content entries)
│       └── ContentValue → FieldValues::* (polymorphic values)
├── Category (organizes components)
│   └── Component (reusable field collections)
│       └── Field
```

### Field System
- **Polymorphic values**: Each field type has its own table (FieldValues::String, Text, Integer, Boolean, Attachment)
- **Layout system**: Fields have row/position/width for responsive form layouts. Half-width fields can be paired.
- **Soft deletes**: Fields use `SoftDeletable` concern with `deleted_at` column

### Key Concerns
- `SoftDeletable` - Soft delete with `discard`/`undiscard`, default scope excludes deleted
- `Sluggable` - Auto-generates unique slugs from names, scoped by organization

### Prefixed IDs
All models use semantic prefixed IDs via `prefixed_ids` gem:
- `ctype_*` ContentType, `cnt_*` Content, `fld_*` Field, `comp_*` Component, `cat_*` Category

## Frontend Stack

- **Bundler**: esbuild
- **CSS**: Tailwind CSS v4.0 + DaisyUI v5.5
- **Interactivity**: Hotwired (Turbo + Stimulus)
- **Stimulus controllers**: Located in `app/javascript/controllers/`

## Testing

Uses RSpec with FactoryBot. Dummy Rails app in `spec/dummy/` for testing the engine. Factories in `spec/factories/`.

## Code Style

Follows Rails Omakase style guide via `rubocop-rails-omakase`. Run `bundle exec rubocop` before committing.

## Engine Mounting

Routes are mounted via `RivetCms::Engine.routes`. Main routes:
- `/` - Dashboard
- `/content_types` - Content type management with nested fields
- `/components` - Reusable component management
