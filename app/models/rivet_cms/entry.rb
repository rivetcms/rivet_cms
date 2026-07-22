module RivetCms
  # Read-only view of one serialized document, as returned by the Ruby content
  # helpers. Field values are reachable as methods (entry.title), via [] for
  # keys that collide with real methods (entry[:slug]), or through #data.
  class Entry
    def initialize(serialized)
      @hash = serialized
    end

    def id
      @hash[:id]
    end

    def slug
      @hash[:slug]
    end

    def content_type
      @hash[:content_type]
    end

    def state
      @hash[:state]
    end

    def data
      @hash[:data] || {}
    end

    def to_h
      @hash
    end

    def published?
      state.to_s == "published"
    end

    def [](key)
      wrap(data[key.to_s])
    end

    def key?(key)
      data.key?(key.to_s)
    end

    def method_missing(name, *args, &block)
      key = name.to_s
      return wrap(data[key]) if args.empty? && block.nil? && data.key?(key)

      super
    end

    def respond_to_missing?(name, include_private = false)
      data.key?(name.to_s) || super
    end

    def inspect
      "#<RivetCms::Entry #{content_type}/#{slug} (#{state})>"
    end

    private

    # Populated references become nested entries; everything else (scalars,
    # media hashes, component hashes, shallow refs) passes through untouched.
    def wrap(value)
      case value
      when Hash then value.key?(:data) ? Entry.new(value) : value
      when Array then value.map { |item| wrap(item) }
      else value
      end
    end
  end
end
