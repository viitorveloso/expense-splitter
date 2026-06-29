# frozen_string_literal: true

module ExpenseSplitter
  module Splits
    # Splits by integer shares/weights (e.g. 2:1:1 - one person covers half).
    # Handy for "I'll take a double portion". Weights must be positive
    # integers covering every participant.
    class ShareSplit < BaseSplit
      include Apportionment

      # shares: { member_id => Integer }
      def initialize(shares:)
        @shares = shares
      end

      private

      def validate!(member_ids)
        unless @shares.keys.sort_by(&:to_s) == member_ids.sort_by(&:to_s)
          raise SplitError, "share split must cover every participant"
        end
        return if @shares.values.all? { |w| w.is_a?(Integer) && w.positive? }

        raise SplitError, "shares must be positive integers"
      end

      def allocate(total_cents, member_ids)
        weights = member_ids.to_h { |id| [id, @shares.fetch(id)] }
        apportion(total_cents, weights)
      end
    end
  end
end
