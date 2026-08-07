module RivetCms
  # One observability stream over every admin mutation, fired as the :audit
  # hook. Named events (:publish, :prune) are behavior hooks carrying rich
  # domain objects for a specific moment; :audit is uniform who/what/when
  # data for consumers that want all of it (audit logs, activity feeds,
  # SIEM pipelines).
  #
  #   RivetCms.on(:audit) do |event|
  #     AuditRow.create!(action: event.action, subject: event.subject_id, ...)
  #   end
  #
  # The payload is plain values plus the actor object; subscribers must
  # tolerate unknown actions, since the vocabulary grows in minor releases.
  # CE audits admin UI mutations; console and seed changes are not recorded.
  AuditEvent = Struct.new(:action, :subject_type, :subject_id, :subject_label,
                          :organization_id, :actor, :metadata, :at, keyword_init: true)

  module Audit
    class << self
      def record(action, subject:, actor:, organization:, metadata: {})
        event = AuditEvent.new(
          action: action.to_s,
          subject_type: subject.class.name.demodulize.underscore,
          subject_id: subject.try(:prefix_id) || subject.id,
          subject_label: label_for(subject),
          organization_id: organization&.id,
          actor: actor,
          metadata: metadata,
          at: Time.current
        )
        Hooks.run(:audit, event)
        event
      end

      private

      def label_for(subject)
        (subject.try(:name) || subject.try(:label) || subject.try(:slug) ||
         subject.try(:title) || subject.try(:filename))&.to_s
      end
    end
  end
end
