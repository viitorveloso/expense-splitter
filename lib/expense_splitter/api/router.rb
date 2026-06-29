# frozen_string_literal: true

module ExpenseSplitter
  module API
    # A tiny path router. Routes like "/groups/:id/members" compile to a
    # regexp with a named capture, so matching also extracts path params.
    # Deliberately minimal - just enough to keep the HTTP layer declarative
    # without pulling in a web framework.
    class Router
      Route = Struct.new(:verb, :pattern, :handler)

      def initialize
        @routes = []
      end

      def on(verb, path, handler)
        @routes << Route.new(verb, compile(path), handler)
        self
      end

      # @return [[Symbol, Hash]] the handler name and captured params,
      #   or nil if nothing matched.
      def resolve(verb, path)
        @routes.each do |route|
          next unless route.verb == verb

          match = route.pattern.match(path)
          return [route.handler, symbolize(match.named_captures)] if match
        end
        nil
      end

      private

      def compile(path)
        segments = path.split("/").map do |segment|
          segment.start_with?(":") ? "(?<#{segment[1..]}>[^/]+)" : Regexp.escape(segment)
        end
        Regexp.new("\\A#{segments.join("/")}\\z")
      end

      def symbolize(captures)
        captures.transform_keys(&:to_sym)
      end
    end
  end
end
