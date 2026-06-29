# frozen_string_literal: true

module ExpenseSplitter
  module Splits
    # Each participant owes an explicit amount. Useful when someone ordered
    # the lobster and someone else had a salad. The given amounts must cover
    # exactly the participants and add up to the expense total (the base
    # class enforces the sum).
    class ExactSplit < BaseSplit
      # amounts: { member_id => Money }
      def initialize(amounts:)
        @amounts = amounts
      end

      private

      def validate!(member_ids)
        return if @amounts.keys.sort_by(&:to_s) == member_ids.sort_by(&:to_s)

        raise SplitError, "exact split must list an amount for every participant"
      end

      def allocate(_total_cents, _member_ids)
        @amounts.transform_values(&:cents)
      end
    end
  end
end
