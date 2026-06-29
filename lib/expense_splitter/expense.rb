# frozen_string_literal: true

module ExpenseSplitter
  # A single expense: someone (the payer) fronted an amount, and it gets
  # divided among the participants according to a split strategy.
  class Expense
    attr_reader :id, :description, :payer_id, :amount, :participant_ids, :split

    def initialize(id:, description:, payer_id:, amount:, participant_ids:, split:)
      raise ValidationError, "amount must be positive" unless amount.positive?
      raise ValidationError, "expense needs at least one participant" if participant_ids.empty?
      raise ValidationError, "description can't be blank" if description.to_s.strip.empty?

      @id = id
      @description = description
      @payer_id = payer_id
      @amount = amount
      @participant_ids = participant_ids.uniq
      @split = split
      freeze
    end

    # { member_id => Money } each participant owes for this expense.
    def shares
      split.shares_for(total: amount, member_ids: participant_ids)
    end

    # How this expense moves each member's running balance, in cents.
    # The payer is credited the full amount (they paid it), and every
    # participant is debited their share. The net always sums to zero.
    def balance_effect
      effect = Hash.new(0)
      effect[payer_id] += amount.cents
      shares.each { |member_id, owed| effect[member_id] -= owed.cents }
      effect
    end
  end
end
