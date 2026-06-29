# frozen_string_literal: true

module ExpenseSplitter
  module Splits
    # Strategy interface for "how is this expense divided?".
    #
    # Subclasses implement #allocate (pure integer-cent math) and may add
    # parameter validation in #validate!. The base class guarantees the
    # post-condition every split must honour: the allocation sums to exactly
    # the total. That invariant is enforced here, once, for all strategies.
    class BaseSplit
      # Returns { member_id => Money } owed by each participant.
      def shares_for(total:, member_ids:)
        raise SplitError, "a split needs at least one participant" if member_ids.empty?

        validate!(member_ids)
        allocation = allocate(total.cents, member_ids)
        ensure_balanced!(allocation, total.cents)
        allocation.transform_values { |cents| Money.new(cents) }
      end

      # Short name used in serialized output, e.g. "equal", "percentage".
      def type
        self.class.name.split("::").last.sub(/Split\z/, "").gsub(/([a-z])([A-Z])/, '\1_\2').downcase
      end

      private

      def allocate(_total_cents, _member_ids)
        raise NotImplementedError, "#{self.class} must implement #allocate"
      end

      def validate!(_member_ids); end

      def ensure_balanced!(allocation, total_cents)
        actual = allocation.values.sum
        return if actual == total_cents

        raise SplitError, "split allocates #{actual} cents but the total is #{total_cents}"
      end
    end
  end
end
