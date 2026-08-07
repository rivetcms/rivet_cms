module RivetCms
  # Lifecycle event registry: the extension seam host apps (and the Pro
  # engine) attach through. Subscribers must not raise into the publish
  # path; failures are logged and swallowed.
  #
  #   RivetCms::Hooks.on(:publish) { |revision| ... }
  #
  # Registration is idempotent per key: re-registering with the same key
  # replaces the previous handler instead of adding a duplicate. Anonymous
  # handlers key on their own identity, which is stable when registration
  # happens in an initializer (runs once per boot). Code that registers from
  # a reloadable context (e.g. to_prepare) must pass an explicit key, or
  # every reload adds another copy:
  #
  #   RivetCms::Hooks.on(:publish, key: :sitemap) { |revision| ... }
  #
  # Subscribers run in registration order; there is no ordering API, so no
  # subscriber may depend on running before or after another.
  #
  # Extensions can define their own events before subscribing or firing:
  #
  #   RivetCms::Hooks.register_event(:unpublish)
  #
  # Built-in events:
  #   :publish - a document revision was published (fires after commit,
  #              receives the published snapshot revision)
  #   :prune   - a superseded revision is about to be destroyed by retention
  #              (fires inside the publish transaction, before the delete, so
  #              a subscriber can archive it elsewhere first)
  module Hooks
    BUILT_IN_EVENTS = %i[publish prune].freeze
    MUTEX = Mutex.new

    class << self
      def register_event(event)
        mutex.synchronize { known_events << event.to_sym }
        event.to_sym
      end

      def events
        mutex.synchronize { known_events.to_a }
      end

      def on(event, callable = nil, key: nil, &block)
        handler = callable || block
        raise ArgumentError, "handler required" if handler.nil?

        mutex.synchronize do
          raise ArgumentError, "unknown event: #{event} (register_event it first)" unless known_events.include?(event)

          registry[event][key || handler] = handler
        end
        handler
      end

      def run(event, *args)
        handlers = mutex.synchronize { registry.key?(event) ? registry[event].values : [] }
        handlers.each do |handler|
          handler.call(*args)
        rescue => error
          Rails.logger&.error("[RivetCms] #{event} hook failed: #{error.class}: #{error.message}")
        end
      end

      # Test-only: capture subscriptions so an example can register handlers
      # and hand the registry back exactly as it found it.
      def snapshot
        mutex.synchronize { registry.transform_values(&:dup) }
      end

      def restore(snapshot)
        return if snapshot.nil? # never mistake a failed snapshot for "no subscribers"

        mutex.synchronize do
          @registry = Hash.new { |hash, event| hash[event] = {} }
          snapshot&.each { |event, handlers| @registry[event] = handlers.dup }
        end
      end

      # Test-only: wipes ALL subscribers including the engine's boot-time
      # registrations (initializers do not rerun). Pair with snapshot/restore.
      def reset!
        mutex.synchronize do
          @registry = nil
          @known_events = nil
        end
      end

      private

      def mutex
        MUTEX
      end

      def registry
        @registry ||= Hash.new { |hash, event| hash[event] = {} }
      end

      def known_events
        @known_events ||= Set.new(BUILT_IN_EVENTS)
      end
    end
  end
end
