# frozen_string_literal: true

require_relative "test_helper"

module ExpenseSplitter
  # Exercises the full HTTP surface through Application#call - no server, no
  # sockets, just (verb, path, body) in and [status, hash] out.
  class APITest < TestCase
    def setup
      @app = API::Application.new
    end

    def test_create_group
      status, body = post("/groups", name: "Trip")
      assert_equal 201, status
      assert_equal "Trip", body[:name]
      assert_match(/\Agrp_/, body[:id])
    end

    def test_unknown_route_returns_404
      status, body = @app.call("GET", "/nope", "")
      assert_equal 404, status
      assert body[:error]
    end

    def test_unknown_group_returns_404
      status, = @app.call("GET", "/groups/grp_999", "")
      assert_equal 404, status
    end

    def test_malformed_json_returns_400
      status, body = @app.call("POST", "/groups", "{not json")
      assert_equal 400, status
      assert body[:error]
    end

    def test_missing_parameter_returns_422
      status, body = post("/groups", {}) # no name
      assert_equal 422, status
      assert_match(/name/, body[:error])
    end

    def test_invalid_split_returns_422
      group_id = create_group
      alice = add_member(group_id, "Alice")
      bob = add_member(group_id, "Bob")

      status, body = post("/groups/#{group_id}/expenses",
                          description: "Bad",
                          payer_id: alice,
                          amount_cents: 1000,
                          participant_ids: [alice, bob],
                          split: { "type" => "percentage", "percentages" => { alice => 50, bob => 40 } })
      assert_equal 422, status
      assert body[:error]
    end

    def test_full_flow_produces_settlements
      group_id = create_group
      alice = add_member(group_id, "Alice")
      bob = add_member(group_id, "Bob")
      carol = add_member(group_id, "Carol")

      status, = post("/groups/#{group_id}/expenses",
                     description: "Hotel",
                     payer_id: alice,
                     amount_cents: 30_000,
                     participant_ids: [alice, bob, carol],
                     split: { "type" => "equal" })
      assert_equal 201, status

      status, balances = @app.call("GET", "/groups/#{group_id}/balances", "")
      assert_equal 200, status
      rows = balances[:balances]
      assert_equal 0, rows.sum { |row| row[:balance_cents] }

      alice_row = rows.find { |row| row[:member_id] == alice }
      assert_equal 20_000, alice_row[:balance_cents] # paid 300, owes 100 of it

      status, settlements = @app.call("GET", "/groups/#{group_id}/settlements", "")
      assert_equal 200, status
      transfers = settlements[:settlements]
      assert_equal 2, transfers.size
      assert transfers.all? { |t| t[:to] == alice }
      assert_equal 20_000, transfers.sum { |t| t[:amount_cents] }
    end

    def test_show_group_is_detailed
      group_id = create_group
      add_member(group_id, "Solo")
      status, body = @app.call("GET", "/groups/#{group_id}", "")
      assert_equal 200, status
      assert body.key?(:expenses)
      assert body.key?(:balances)
      assert body.key?(:settlements)
    end

    private

    def post(path, payload)
      @app.call("POST", path, JSON.generate(payload))
    end

    def create_group
      _, body = post("/groups", name: "Trip")
      body[:id]
    end

    def add_member(group_id, name)
      _, body = post("/groups/#{group_id}/members", name: name)
      body[:id]
    end
  end
end
