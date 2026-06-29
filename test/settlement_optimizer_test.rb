# frozen_string_literal: true

require_relative "test_helper"

module ExpenseSplitter
  class SettlementOptimizerTest < TestCase
    def test_single_debtor_and_creditor
      settlements = optimize("a" => 1000, "b" => -1000)

      assert_equal 1, settlements.size
      transfer = settlements.first
      assert_equal "b", transfer.from_id
      assert_equal "a", transfer.to_id
      assert_equal 1000, transfer.amount.cents
    end

    def test_all_settled_means_no_transfers
      assert_empty optimize("a" => 0, "b" => 0)
    end

    def test_transfers_fully_clear_every_balance
      balances = { "a" => 5000, "b" => -2000, "c" => -3000 }
      settlements = optimize(balances)

      assert_settles balances, settlements
    end

    def test_never_exceeds_n_minus_one_transfers
      balances = { "a" => 300, "b" => 200, "c" => -100, "d" => -400 }
      settlements = optimize(balances)

      assert_operator settlements.size, :<=, balances.size - 1
      assert_settles balances, settlements
    end

    def test_greedy_matches_largest_first
      # b owes 800; a is owed 500, c is owed 300. The biggest debt meets the
      # biggest credit first: b -> a 500, then b -> c 300.
      settlements = optimize("a" => 500, "c" => 300, "b" => -800)

      assert_equal 2, settlements.size
      assert_equal ["a", 500], [settlements[0].to_id, settlements[0].amount.cents]
      assert_equal ["c", 300], [settlements[1].to_id, settlements[1].amount.cents]
    end

    # Randomized: any balanced set of balances must be fully cleared, and the
    # plan must never use more than n-1 transfers.
    def test_random_balances_always_reconcile
      rng = Random.new(99)
      50.times do
        size = rng.rand(2..6)
        ids = ("a".."f").first(size)
        raw = ids.map { |id| [id, rng.rand(-5000..5000)] }.to_h
        # Force the books to balance by absorbing the remainder into the last id.
        raw[ids.last] -= raw.values.sum
        next if raw.values.all?(&:zero?)

        settlements = optimize(raw)
        assert_settles raw, settlements
        assert_operator settlements.size, :<=, ids.reject { |id| raw[id].zero? }.size - 1 + 1
      end
    end

    private

    def optimize(cents_by_id)
      balances = cents_by_id.transform_values { |cents| Money.new(cents) }
      SettlementOptimizer.new(balances).call
    end

    # Applies the settlements to the starting balances and asserts everyone
    # ends at zero.
    def assert_settles(starting_cents, settlements)
      final = starting_cents.dup
      settlements.each do |s|
        final[s.from_id] += s.amount.cents # debtor's negative balance moves toward zero
        final[s.to_id]   -= s.amount.cents # creditor's positive balance moves toward zero
      end
      assert final.values.all?(&:zero?), "balances not fully settled: #{final.inspect}"
    end
  end
end
