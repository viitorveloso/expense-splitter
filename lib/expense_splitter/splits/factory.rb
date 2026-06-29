# frozen_string_literal: true

module ExpenseSplitter
  module Splits
    # Turns a plain JSON-ish hash (from the API layer) into the right split
    # strategy object. Keeping this in one place means the wire format and the
    # domain objects can evolve independently.
    module Factory
      module_function

      def build(spec)
        type = spec.fetch("type") { raise SplitError, "split needs a \"type\"" }

        case type
        when "equal"
          EqualSplit.new
        when "exact"
          ExactSplit.new(amounts: money_map(spec.fetch("amounts")))
        when "percentage"
          PercentageSplit.new(percentages: numeric_map(spec.fetch("percentages")))
        when "share"
          ShareSplit.new(shares: integer_map(spec.fetch("shares")))
        else
          raise SplitError, "unknown split type: #{type.inspect}"
        end
      end

      def money_map(raw)
        raw.transform_values { |cents| Money.new(Integer(cents)) }
      end

      def integer_map(raw)
        raw.transform_values { |value| Integer(value) }
      end

      def numeric_map(raw)
        raw.transform_values { |value| Float(value) }
      end
    end
  end
end
