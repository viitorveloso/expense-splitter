# frozen_string_literal: true

module ExpenseSplitter
  module Splits
    # Splits by percentage (e.g. 70/30). Percentages must cover every
    # participant and add up to 100. Rounding is handled by the
    # largest-remainder method so the parts still reconcile to the cent.
    class PercentageSplit < BaseSplit
      include Apportionment

      EPSILON = 1e-9

      # percentages: { member_id => Numeric }
      def initialize(percentages:)
        @percentages = percentages
      end

      private

      def validate!(member_ids)
        unless @percentages.keys.sort_by(&:to_s) == member_ids.sort_by(&:to_s)
          raise SplitError, "percentage split must cover every participant"
        end

        total = @percentages.values.sum
        return if (total - 100).abs < EPSILON

        raise SplitError, "percentages must add up to 100 (got #{total})"
      end

      def allocate(total_cents, member_ids)
        # Scale to integers to keep apportionment in exact rational arithmetic.
        weights = member_ids.to_h { |id| [id, (@percentages.fetch(id) * 1_000_000).round] }
        apportion(total_cents, weights)
      end
    end
  end
end
