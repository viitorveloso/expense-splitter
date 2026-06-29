# frozen_string_literal: true

module ExpenseSplitter
  module API
    # The HTTP application, expressed as a pure function of the request.
    #
    # #call takes (verb, path, raw_body) and returns [status, hash]. It has no
    # dependency on WEBrick or sockets, which means the entire API surface can
    # be tested in-process with plain method calls - no server, no ports. The
    # Server class is just a thin adapter that feeds real requests into #call.
    class Application
      def initialize(repository: Repository.new)
        @repository = repository
        @router = build_router
      end

      # @return [[Integer, Hash]]
      def call(verb, path, raw_body = "")
        handler, params = @router.resolve(verb, path)
        return error(404, "no route for #{verb} #{path}") unless handler

        send(handler, params, parse_body(raw_body))
      rescue KeyError => e
        error(422, "missing parameter: #{e.message}")
      rescue ArgumentError, TypeError => e
        error(422, "invalid parameter: #{e.message}")
      rescue ValidationError => e
        error(422, e.message)
      rescue UnknownMemberError, NotFoundError => e
        error(404, e.message)
      rescue JSON::ParserError
        error(400, "request body must be valid JSON")
      end

      private

      def build_router
        Router.new
          .on("POST", "/groups", :create_group)
          .on("GET",  "/groups/:id", :show_group)
          .on("POST", "/groups/:id/members", :add_member)
          .on("POST", "/groups/:id/expenses", :add_expense)
          .on("GET",  "/groups/:id/balances", :show_balances)
          .on("GET",  "/groups/:id/settlements", :show_settlements)
      end

      def create_group(_params, body)
        group = @repository.create_group(name: body.fetch("name"))
        [201, Serializer.group(group)]
      end

      def show_group(params, _body)
        group = @repository.group(params.fetch(:id))
        [200, Serializer.group(group, detailed: true)]
      end

      def add_member(params, body)
        group = @repository.group(params.fetch(:id))
        member = Member.new(id: @repository.next_id("mbr"), name: body.fetch("name"))
        group.add_member(member)
        [201, Serializer.member(member)]
      end

      def add_expense(params, body)
        group = @repository.group(params.fetch(:id))
        expense = Expense.new(
          id: @repository.next_id("exp"),
          description: body.fetch("description"),
          payer_id: body.fetch("payer_id"),
          amount: Money.new(Integer(body.fetch("amount_cents"))),
          participant_ids: Array(body.fetch("participant_ids")),
          split: Splits::Factory.build(body.fetch("split"))
        )
        group.add_expense(expense)
        [201, Serializer.expense(expense)]
      end

      def show_balances(params, _body)
        group = @repository.group(params.fetch(:id))
        [200, Serializer.balances(group)]
      end

      def show_settlements(params, _body)
        group = @repository.group(params.fetch(:id))
        [200, Serializer.settlements(group)]
      end

      def parse_body(raw_body)
        return {} if raw_body.nil? || raw_body.strip.empty?

        JSON.parse(raw_body)
      end

      def error(status, message)
        [status, { error: message }]
      end
    end
  end
end
