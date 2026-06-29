# frozen_string_literal: true

require_relative "test_helper"

module ExpenseSplitter
  class SplitsTest < TestCase
    def test_equal_split_distributes_remainder_cents
      shares = Splits::EqualSplit.new.shares_for(total: Money.new(1000), member_ids: %w[a b c])
      assert_equal({ "a" => 334, "b" => 333, "c" => 333 }, cents(shares))
      assert_total 1000, shares
    end

    def test_equal_split_divides_evenly_when_possible
      shares = Splits::EqualSplit.new.shares_for(total: Money.new(900), member_ids: %w[a b c])
      assert_equal({ "a" => 300, "b" => 300, "c" => 300 }, cents(shares))
    end

    def test_exact_split_uses_given_amounts
      split = Splits::ExactSplit.new(amounts: { "a" => Money.new(700), "b" => Money.new(300) })
      shares = split.shares_for(total: Money.new(1000), member_ids: %w[a b])
      assert_equal({ "a" => 700, "b" => 300 }, cents(shares))
    end

    def test_exact_split_rejects_mismatched_total
      split = Splits::ExactSplit.new(amounts: { "a" => Money.new(700), "b" => Money.new(200) })
      assert_raises(SplitError) do
        split.shares_for(total: Money.new(1000), member_ids: %w[a b])
      end
    end

    def test_exact_split_requires_every_participant
      split = Splits::ExactSplit.new(amounts: { "a" => Money.new(1000) })
      assert_raises(SplitError) do
        split.shares_for(total: Money.new(1000), member_ids: %w[a b])
      end
    end

    def test_percentage_split_reconciles_to_the_cent
      split = Splits::PercentageSplit.new(percentages: { "a" => 33.34, "b" => 33.33, "c" => 33.33 })
      shares = split.shares_for(total: Money.new(1000), member_ids: %w[a b c])
      assert_equal({ "a" => 334, "b" => 333, "c" => 333 }, cents(shares))
      assert_total 1000, shares
    end

    def test_percentage_split_rejects_when_not_hundred
      split = Splits::PercentageSplit.new(percentages: { "a" => 50, "b" => 40 })
      assert_raises(SplitError) do
        split.shares_for(total: Money.new(1000), member_ids: %w[a b])
      end
    end

    def test_share_split_weights_amounts
      split = Splits::ShareSplit.new(shares: { "a" => 1, "b" => 2, "c" => 1 })
      shares = split.shares_for(total: Money.new(1000), member_ids: %w[a b c])
      assert_equal({ "a" => 250, "b" => 500, "c" => 250 }, cents(shares))
      assert_total 1000, shares
    end

    def test_share_split_handles_indivisible_totals
      split = Splits::ShareSplit.new(shares: { "a" => 1, "b" => 1, "c" => 1 })
      shares = split.shares_for(total: Money.new(1000), member_ids: %w[a b c])
      assert_total 1000, shares
    end

    def test_share_split_rejects_non_positive_weights
      split = Splits::ShareSplit.new(shares: { "a" => 0, "b" => 1 })
      assert_raises(SplitError) do
        split.shares_for(total: Money.new(1000), member_ids: %w[a b])
      end
    end

    def test_split_type_names
      assert_equal "equal", Splits::EqualSplit.new.type
      assert_equal "percentage", Splits::PercentageSplit.new(percentages: {}).type
    end

    # Property check: no matter the weights or total, shares always reconcile.
    def test_apportionment_never_loses_or_creates_cents
      rng = Random.new(1234)
      40.times do
        total = rng.rand(1..100_000)
        ids = ("a".."e").first(rng.rand(2..5))
        weights = ids.to_h { |id| [id, rng.rand(1..9)] }
        shares = Splits::ShareSplit.new(shares: weights)
                                   .shares_for(total: Money.new(total), member_ids: ids)
        assert_equal total, shares.values.sum(&:cents)
      end
    end

    private

    def cents(shares)
      shares.transform_values(&:cents)
    end

    def assert_total(expected, shares)
      assert_equal expected, shares.values.sum(&:cents), "shares must reconcile to the total"
    end
  end
end
