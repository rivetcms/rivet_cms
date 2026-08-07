module RivetCms
  # Enforces retention for one document: keeps the newest N superseded
  # published snapshots per locale and destroys the rest. Candidates exclude
  # the document's live pointers, re-read from the database so a stale
  # in-memory copy cannot target a revision another request just published,
  # and pruning is skipped entirely unless a live published revision exists.
  class RevisionPruner
    def initialize(document, keep_ids: [])
      @document = document
      @keep_ids = Array(keep_ids).compact
      @destroyed = 0
    end

    def prune!
      @destroyed = 0 # defensive: report this run, not a previous one
      retention = RivetCms.normalized_retention_for(@document)
      return 0 if retention == :all

      published_id, draft_id = live_pointers
      return 0 if published_id.nil? # nothing is live: never guess what to keep

      protected_ids = ([ published_id, draft_id ] + @keep_ids).compact
      live_locale = DocumentRevision.where(id: published_id).pick(:locale)

      # Retention applies per locale so one locale's publishes cannot destroy
      # another's, and no locale's snapshots become unreachable. A locale with
      # no live pointer keeps its newest snapshot as that locale's live one.
      locales.each do |locale|
        allowance = locale == live_locale ? retention : retention + 1
        doomed = candidates(protected_ids, locale).order(created_at: :desc, id: :desc).offset(allowance)
        doomed.each do |revision|
          Hooks.run(:prune, revision)
          # destroy returns false when a callback halts it; count what actually
          # went, so the count and log cannot overstate the work.
          if revision.destroy
            @destroyed += 1
          else
            Rails.logger&.warn("[RivetCms] could not prune revision #{revision.id}: destroy was halted")
          end
        end
      end

      Rails.logger&.info("[RivetCms] pruned #{@destroyed} superseded revision(s) for document #{@document.id}") if @destroyed.positive?
      @destroyed
    end

    private

    # Read live pointers from the database, not the attribute cache
    def live_pointers
      Document.where(id: @document.id).pick(:published_revision_id, :draft_revision_id) || [ nil, nil ]
    end

    def locales
      @document.revisions.where(state: DocumentRevision.states[:published]).distinct.pluck(:locale)
    end

    def candidates(protected_ids, locale)
      @document.revisions
               .where(state: DocumentRevision.states[:published], locale: locale)
               .where.not(id: protected_ids)
    end
  end
end
