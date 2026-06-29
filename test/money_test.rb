# frozen_string_literal: true

require_relative "test_helper"

module ExpenseSplitter
  class MoneyTest < TestCase
    def test_from_amount_avoids_float_drift
      assert_equal 30, (Money.from_amount("0.10") + Money.from_amount("0.20")).cents
    end

    def test_from_amount_rounds_to_nearest_cent
      assert_equal 1051, Money.from_amount("10.505").cents
    end

    def test_arithmetic_returns_new_money
      a = Money.new(100)
      b = Money.new(40)
      assert_equal 140, (a + b).cents
      assert_equal 60, (a - b).cents
      assert_equal 300, (a * 3).cents
      assert_equal 100, a.cents # original untouched
    end

    def test_is_comparable
      assert Money.new(100) > Money.new(99)
      assert_equal [Money.new(1), Money.new(2), Money.new(3)],
                   [Money.new(3), Money.new(1), Money.new(2)].sort
    end

    def test_is_immutable
      assert Money.new(100).frozen?
    end

    def test_rejects_non_integer_cents
      assert_raises(ArgumentError) { Money.new(10.5) }
    end

    def test_formats_brazilian_currency
      assert_equal "R$ 1.234,56", Money.new(123_456).format
      assert_equal "-R$ 0,05", Money.new(-5).format
      assert_equal "R$ 0,00", Money.zero.format
    end

    def test_equality_and_hashing
      assert_equal Money.new(100), Money.new(100)
      assert_equal 1, [Money.new(100), Money.new(100)].uniq.size
    end
  end
end
