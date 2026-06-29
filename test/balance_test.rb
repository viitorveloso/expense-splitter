# frozen_string_literal: true

require_relative "test_helper"

module ExpenseSplitter
  class BalanceTest < TestCase
    def test_payer_is_credited_and_participants_debited
      group, ids = group_with(:alice, :bob)
      group.add_expense(
        Expense.new(
          id: "e1",
          description: "Lunch",
          payer_id: ids[:alice],
          amount: Money.new(1000),
          participant_ids: [ids[:alice], ids[:bob]],
          split: Splits::EqualSplit.new
        )
      )

      balances = group.balances
      # Alice paid 1000, owes 500 of it => +500. Bob owes his 500 => -500.
      assert_equal 500, balances[ids[:alice]].cents
      assert_equal(-500, balances[ids[:bob]].cents)
    end

    def test_balances_always_sum_to_zero
      group, ids = group_with(:a, :b, :c)
      group.add_expense(expense(ids[:a], 1000, ids.values, Splits::EqualSplit.new))
      group.add_expense(expense(ids[:b], 550, ids.values, Splits::EqualSplit.new))
      group.add_expense(
        expense(ids[:c], 1200, [ids[:a], ids[:c]],
                Splits::ShareSplit.new(shares: { ids[:a] => 1, ids[:c] => 3 }))
      )

      assert_equal 0, group.balances.values.sum(&:cents)
    end

    def test_member_with_no_activity_has_zero_balance
      group, ids = group_with(:a, :b)
      assert_equal 0, group.balances[ids[:a]].cents
      assert_equal 0, group.balances[ids[:b]].cents
    end

    private

    def expense(payer_id, cents, participant_ids, split)
      Expense.new(
        id: "exp-#{rand(10_000)}",
        description: "Expense",
        payer_id: payer_id,
        amount: Money.new(cents),
        participant_ids: participant_ids,
        split: split
      )
    end
  end
end
