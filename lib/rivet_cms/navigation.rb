module RivetCms
  # Admin sidebar registry: the seam the Pro engine adds nav items through.
  # Core registers its own items here too, so every item, core or extension,
  # goes through the same can? filter and a denied user never sees a link
  # that would 403.
  #
  #   RivetCms::Navigation.register :audit_log,
  #     label: "Audit Log",
  #     section: "Manage",
  #     icon: :content,
  #     requires: [:read, :content],
  #     path: -> { audit_log_path },
  #     position: 80
  #
  # path is either a string or a lambda instance_exec'd in the controller, so
  # engine route helpers work directly. requires is [action, resource] for
  # can?, or nil for always visible. icon names one of the built-in sidebar
  # icons; unknown names render a neutral dot. Items sort by position across
  # sections; a section appears where its lowest-position item falls.
  # Re-registering a key replaces the item, so registration is reload-safe.
  module Navigation
    Item = Struct.new(:key, :label, :section, :icon, :requires, :path, :position, :exact, :badge, :visible, keyword_init: true)

    MUTEX = Mutex.new

    class << self
      def register(key, label:, section:, path:, icon: nil, requires: nil, position: 100, exact: false, badge: nil, visible: nil)
        raise ArgumentError, "label required" if label.to_s.strip.empty?
        raise ArgumentError, "path must be a String or callable" unless path.is_a?(String) || path.respond_to?(:call)
        # Class equality, not is_a?: ActiveSupport::Duration answers is_a?(Integer)
        raise ArgumentError, "position must be an Integer" unless position.class == Integer
        raise ArgumentError, "badge must be callable" unless badge.nil? || badge.respond_to?(:call)
        raise ArgumentError, "visible must be callable" unless visible.nil? || visible.respond_to?(:call)
        unless requires.nil? || (requires.is_a?(Array) && requires.size == 2 && requires.all? { |part| part.respond_to?(:to_sym) })
          raise ArgumentError, "requires must be nil or [action, resource]"
        end

        item = Item.new(
          key: key.to_sym, label: label.to_s, section: section.to_s, icon: icon&.to_sym,
          requires: requires&.map(&:to_sym), path: path, position: position, exact: exact == true,
          badge: badge, visible: visible
        )
        mutex.synchronize { registry[item.key] = item }
        item
      end

      def unregister(key)
        mutex.synchronize { registry.delete(key.to_sym) }
      end

      def items
        mutex.synchronize { registry.values.sort_by.with_index { |item, index| [ item.position, index ] } }
      end

      # Test-only: capture registrations so an example can add items and hand
      # the registry back exactly as it found it.
      def snapshot
        mutex.synchronize { registry.dup }
      end

      def restore(snapshot)
        return if snapshot.nil? # never mistake a failed snapshot for "no items"

        mutex.synchronize { @registry = snapshot.dup }
      end

      private

      def mutex
        MUTEX
      end

      def registry
        @registry ||= {}
      end
    end

    # Core items carry the same gates their index actions enforce, so hiding
    # and denying can never disagree.
    register :dashboard, label: "Dashboard", section: "", icon: :dashboard,
             path: -> { root_path }, position: 10, exact: true
    register :content, label: "Content", section: "Manage", icon: :content,
             requires: [ :read, :content ], path: -> { content_path }, position: 20
    register :content_types, label: "Content Types", section: "Manage", icon: :content_types,
             requires: [ :read, :schema ], path: -> { content_types_path }, position: 30
    register :components, label: "Components", section: "Manage", icon: :components,
             requires: [ :read, :schema ], path: -> { components_path }, position: 40
    register :media, label: "Media", section: "Manage", icon: :media,
             requires: [ :read, :media ], path: -> { media_assets_path }, position: 50
    # The badge counts what the trash page would show this user: entries
    # always (the item itself is content-gated), removed types only with
    # schema read, mirroring the page's sections. Within a domain the count
    # is an aggregate, not filtered per record, like stat counts.
    register :trash, label: "Trash", section: "Manage", icon: :trash,
             requires: [ :read, :content ], path: -> { trash_path }, position: 55,
             badge: -> {
               count = Document.with_discarded.discarded.in_visible_types.where(organization: Current.organization).count
               count += ContentType.with_discarded.discarded.where(organization: Current.organization).count if can?(:read, :schema)
               count
             }
    # Only exists in built-in auth mode; hosts with their own auth manage
    # users in their own admin
    register :users, label: "Users", section: "Manage", icon: :users,
             requires: [ :read, :users ], path: -> { users_path }, position: 58,
             visible: -> { RivetCms.builtin_auth? }
    register :api, label: "API", section: "Deliver", icon: :api,
             requires: [ :read, :api ], path: -> { api_docs_path }, position: 60
    register :api_tokens, label: "API Tokens", section: "Deliver", icon: :api_tokens,
             requires: [ :read, :api ], path: -> { api_tokens_path }, position: 70
  end
end
