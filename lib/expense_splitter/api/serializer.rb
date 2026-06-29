# frozen_string_literal: true

module ExpenseSplitter
  module API
    # Translates domain objects into plain hashes for JSON output. Amounts are
    # exposed both as integer cents (unambiguous, safe for clients to compute
    # on) and as a formatted string (ready to show a human).
    module Serializer
      module_function

      def group(group, detailed: false)
        payload = {
          id: group.id,
          name: group.name,
          members: group.members.map(&:to_h)
        }
        return payload unless detailed

        payload.merge(
          expenses: group.expenses.map { |expense| expense(expense) },
          balances: balances(group).fetch(:balances),
          settlements: settlements(group).fetch(:settlements)
        )
      end

      def member(member)
        member.to_h
      end

      def expense(expense)
        {
          id: expense.id,
          description: expense.description,
          payer_id: expense.payer_id,
          amount_cents: expense.amount.cents,
          amount: expense.amount.format,
          split: expense.split.type,
          participant_ids: expense.participant_ids,
          shares: expense.shares.transform_values(&:cents)
        }
      end

      def balances(group)
        rows = group.balances.map do |member_id, money|
          { member_id: member_id, balance_cents: money.cents, balance: money.format }
        end
        { balances: rows }
      end

      def settlements(group)
        { settlements: group.settlements.map(&:to_h) }
      end
    end
  end
end
