module RivetCms
  # Compiles and matches admin-supplied regex patterns without letting a
  # pathological pattern hang the process. Ruby 3.2+ supports a per-regexp
  # timeout; on older Rubies patterns still work, bounded only by MAX_LENGTH.
  module SafePattern
    MAX_LENGTH = 200
    TIMEOUT_SECONDS = 1

    class << self
      def valid?(source)
        return false if source.to_s.length > MAX_LENGTH

        compile(source)
        true
      rescue RegexpError, ArgumentError
        false
      end

      def match?(source, value)
        compile(source).match?(value.to_s)
      rescue RegexpError, ArgumentError
        false
      rescue => error
        raise unless defined?(Regexp::TimeoutError) && error.is_a?(Regexp::TimeoutError)

        false
      end

      private

      def compile(source)
        if Regexp.respond_to?(:timeout)
          Regexp.new(source.to_s, timeout: TIMEOUT_SECONDS)
        else
          Regexp.new(source.to_s)
        end
      end
    end
  end
end
