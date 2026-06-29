# frozen_string_literal: true

module ExpenseSplitter
  # Computes each member's net position across all of a group's expenses.
  #
  # A positive balance means the group owes that member money; a negative
  # balance means the member owes the group. Because every expense nets to
  # zero, the whole group's balances always sum to zero too - a cheap, strong
  # invariant to lean on in tests.
  class Balance
    def initialize(members:, expenses:)
      @members = members
      @expenses = expenses
    end

    # { member_id => Money }
    def net
      totals = @members.to_h { |member| [member.id, 0] }
      @expenses.each do |expense|
        expense.balance_effect.each { |member_id, cents| totals[member_id] += cents }
      end
      totals.transform_values { |cents| Money.new(cents) }
    end
  end
end
