# frozen_string_literal: true

module ExpenseSplitter
  # An instruction to make one group square up with another: "from_id pays
  # to_id this amount". Produced by the SettlementOptimizer.
  class Settlement
    attr_reader :from_id, :to_id, :amount

    def initialize(from_id:, to_id:, amount:)
      @from_id = from_id
      @to_id = to_id
      @amount = amount
      freeze
    end

    def to_h
      { from: from_id, to: to_id, amount_cents: amount.cents, amount: amount.format }
    end
  end
end
