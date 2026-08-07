# Changelog

All notable changes to RivetCMS are documented here.

## Unreleased

### Added
- Entries are soft-deleted and have a trash, matching content types: deleting
  keeps every revision and value, the entry stops being served by the delivery
  API, and it can be restored. Permanent deletion is available from the trash
  only, and requires typing the name for a content type.
- Revision retention: `RivetCms.revision_retention` (`:all` by default, or an
  integer) controls how many superseded published snapshots each document
  keeps. The default keeps everything; pruning is opt-in and applies as each
  document is published.
- `:prune` lifecycle event, fired before a superseded revision is destroyed so
  extensions can archive it first.
- `RivetCms.retention_for(document)` so retention can vary per organization or
  content type.
- `DocumentRevision.restore_owned_into(source, target)`, the rollback
  primitive a revision-history feature builds on.
- Published snapshots record who published them, which is not always the
  person who last saved the draft.

### Changed
- Nothing. Publishing keeps every snapshot unless a host opts into pruning.
