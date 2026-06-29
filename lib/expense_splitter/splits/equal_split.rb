# frozen_string_literal: true

module ExpenseSplitter
  module Splits
    # Splits the bill evenly. When the amount doesn't divide cleanly, the
    # leftover cents are handed to the first participants in order, so e.g.
    # R$ 10,00 across 3 people becomes 3,34 / 3,33 / 3,33.
    class EqualSplit < BaseSplit
      private

      def allocate(total_cents, member_ids)
        base, remainder = total_cents.divmod(member_ids.size)
        member_ids.each_with_index.to_h do |id, index|
          [id, base + (index < remainder ? 1 : 0)]
        end
      end
    end
  end
end
