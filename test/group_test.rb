# frozen_string_literal: true

require_relative "test_helper"

module ExpenseSplitter
  class GroupTest < TestCase
    def test_rejects_expense_with_unknown_payer
      group, ids = group_with(:alice)
      bad = Expense.new(
        id: "e1",
        description: "Mystery",
        payer_id: "ghost",
        amount: Money.new(500),
        participant_ids: [ids[:alice]],
        split: Splits::EqualSplit.new
      )
      assert_raises(UnknownMemberError) { group.add_expense(bad) }
    end

    def test_rejects_expense_with_unknown_participant
      group, ids = group_with(:alice)
      bad = Expense.new(
        id: "e1",
        description: "Mystery",
        payer_id: ids[:alice],
        amount: Money.new(500),
        participant_ids: [ids[:alice], "ghost"],
        split: Splits::EqualSplit.new
      )
      assert_raises(UnknownMemberError) { group.add_expense(bad) }
    end

    def test_rejects_blank_group_name
      assert_raises(ValidationError) { Group.new(id: "g", name: "  ") }
    end

    def test_end_to_end_trip_scenario
      group, ids = group_with(:alice, :bob, :carol)
      a = ids[:alice]
      b = ids[:bob]
      c = ids[:carol]

      # Alice covers a 300.00 hotel for everyone, split equally.
      group.add_expense(trip_expense("Hotel", a, 30_000, [a, b, c], Splits::EqualSplit.new))
      # Bob buys 90.00 of groceries, split equally.
      group.add_expense(trip_expense("Groceries", b, 9_000, [a, b, c], Splits::EqualSplit.new))
      # Carol pays a 60.00 dinner, but Alice didn't eat - just Bob and Carol.
      group.add_expense(trip_expense("Dinner", c, 6_000, [b, c], Splits::EqualSplit.new))

      assert_equal 0, group.balances.values.sum(&:cents)

      settlements = group.settlements
      # With 3 people, at most 2 transfers are ever needed.
      assert_operator settlements.size, :<=, 2

      # Re-apply the plan and confirm everyone lands at zero.
      final = group.balances.transform_values(&:cents)
      settlements.each do |s|
        final[s.from_id] += s.amount.cents
        final[s.to_id]   -= s.amount.cents
      end
      assert final.values.all?(&:zero?)
    end

    private

    def trip_expense(description, payer_id, cents, participant_ids, split)
      Expense.new(
        id: "exp-#{description}",
        description: description,
        payer_id: payer_id,
        amount: Money.new(cents),
        participant_ids: participant_ids,
        split: split
      )
    end
  end
end
