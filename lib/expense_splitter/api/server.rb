# frozen_string_literal: true

require "webrick"

module ExpenseSplitter
  module API
    # Thin WEBrick adapter. Its only job is to read a real HTTP request, hand
    # the parts to Application#call, and write the [status, hash] result back
    # as JSON. All behaviour lives in Application; this class stays trivial on
    # purpose so there's nothing here that needs its own tests.
    class Server
      def initialize(port: 4567, application: Application.new)
        @application = application
        @server = WEBrick::HTTPServer.new(
          Port: port,
          Logger: WEBrick::Log.new(File::NULL),
          AccessLog: []
        )
        @server.mount_proc("/") { |request, response| dispatch(request, response) }
        trap("INT") { @server.shutdown }
      end

      def start
        @server.start
      end

      private

      def dispatch(request, response)
        status, payload = @application.call(
          request.request_method,
          request.path,
          request.body.to_s
        )
        response.status = status
        response["Content-Type"] = "application/json"
        response.body = JSON.generate(payload)
      end
    end
  end
end
