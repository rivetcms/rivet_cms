# Changelog

All notable changes to RivetCMS are documented here. While the version is
below 1.0, minor releases may include breaking changes; each one is listed
under a Breaking heading.

## Unreleased

### Changed
- Licensed under LGPL-3.0-or-later.

## 0.2.0 - 2026-08-08

Everything between the initial scaffold and built-in authentication.

### Added
- Deletion is recoverable end to end: content types and entries soft-delete
  into trashes (per type, plus a global Trash page with search, type filter,
  and a sidebar badge). Every revision and value is kept; restoring brings it
  all back. Permanent deletion lives only inside the trash, requires typing
  the name for a content type, and returns you to the page you deleted from.
- Revision retention: `RivetCms.revision_retention` (`:all` by default, or an
  integer). The default keeps every superseded published snapshot; pruning is
  opt-in and applies as each document is published.
  `RivetCms.retention_for(document)` varies retention per organization or
  content type.
- Authorization: `config.can` receives a `RivetCms::AccessCheck` (including
  the affected record when one applies) and gates every admin surface;
  denied records are hidden from lists, docs, and pickers as well as refused.
- Lifecycle hooks (`RivetCms.on`) with `:publish`, `:prune`, and an `:audit`
  stream covering every admin mutation; unsigned webhooks for
  `entry.published`.
- Delivery API: OpenAPI document, published/preview API token scopes,
  filters, sort, pagination, populate, and sparse fields; Ruby content
  helpers (`RivetCms.entries/.entry/.single`) with the same semantics.
- Media library: drag-and-drop upload with sniffed-type checking, title/alt/
  description, search and kind filters, thumbnails for images and (with
  optional poppler/ffmpeg) PDFs and video.
- Editor: rich text (TipTap), markdown, date/datetime, decimal, enumeration,
  regex-validated strings; entry slugs validated and auto-cleaned; branded
  confirm dialogs throughout; cross-type Content page; redesigned dashboard.
- Field layout builder with drag ordering, half-width pairing, and reusable
  components organized in categories.

### Changed
- Entry and content type slugs enforce lowercase-alphanumeric-with-hyphens
  (existing records are grandfathered until edited).
- Admin theme moved to the steel/ink design system (Archivo + JetBrains
  Mono), replacing the indigo default.
