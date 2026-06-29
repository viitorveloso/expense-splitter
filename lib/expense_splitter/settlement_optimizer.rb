# frozen_string_literal: true

module ExpenseSplitter
  # Reduces a set of net balances to a short list of "who pays whom".
  #
  # Strategy (greedy): repeatedly match the member owed the most with the
  # member who owes the most, and transfer the smaller of the two amounts.
  # Every step fully zeroes out at least one member, so the result contains
  # at most (n - 1) transfers for n indebted members.
  #
  # Note: finding the provably minimal number of transactions is NP-hard
  # (it's a variant of subset-sum). This greedy heuristic is the standard,
  # near-optimal approach and is optimal for the common cases. Complexity is
  # O(n^2): up to n rounds, each scanning the remaining ledgers.
  class SettlementOptimizer
    def initialize(balances)
      @balances = balances # { member_id => Money }
    end

    # @return [Array<Settlement>]
    def call
      creditors = ledger(:positive?)                 # owed money (cents > 0)
      debtors   = ledger(:negative?, as_owed: true)  # owe money (stored positive)

      settlements = []
      until creditors.empty? || debtors.empty?
        creditor_id, credit = creditors.max_by { |_, cents| cents }
        debtor_id,   debt   = debtors.max_by { |_, cents| cents }

        transfer = [credit, debt].min
        settlements << Settlement.new(
          from_id: debtor_id,
          to_id: creditor_id,
          amount: Money.new(transfer)
        )

        settle(creditors, creditor_id, credit - transfer)
        settle(debtors, debtor_id, debt - transfer)
      end

      settlements
    end

    private

    def ledger(sign, as_owed: false)
      @balances
        .select { |_, money| money.cents.public_send(sign) }
        .transform_values { |money| as_owed ? -money.cents : money.cents }
    end

    def settle(ledger, id, remaining)
      remaining.zero? ? ledger.delete(id) : ledger[id] = remaining
    end
  end
end
