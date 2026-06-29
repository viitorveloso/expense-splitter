# frozen_string_literal: true

module ExpenseSplitter
  module Splits
    # Largest-remainder apportionment.
    #
    # Distributes an integer amount of cents across weighted buckets so that
    # the parts always add back up to the original total - never a cent more,
    # never a cent less. Each bucket gets the floor of its exact share, then
    # the leftover cents go one-by-one to the buckets with the biggest
    # fractional remainders. Ties break on the (stringified) id so the result
    # is fully deterministic and reproducible.
    module Apportionment
      def apportion(total_cents, weights)
        weight_sum = weights.values.sum
        raise SplitError, "weights must add up to a positive number" unless weight_sum.positive?

        exact = weights.transform_values { |w| Rational(total_cents * w, weight_sum) }
        floors = exact.transform_values(&:floor)

        leftover = total_cents - floors.values.sum
        ranked = exact.sort_by { |id, share| [-(share - share.floor), id.to_s] }.map(&:first)
        ranked.first(leftover).each { |id| floors[id] += 1 }

        floors
      end
    end
  end
end
