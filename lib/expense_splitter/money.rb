# frozen_string_literal: true

module ExpenseSplitter
  # Immutable value object representing money as an integer count of cents.
  #
  # Storing the smallest currency unit as an Integer sidesteps the
  # floating-point rounding bugs that show up the moment you do arithmetic
  # on amounts like 0.1 + 0.2. Every operation returns a new, frozen Money.
  class Money
    include Comparable

    attr_reader :cents

    class << self
      # Builds Money from a human amount, e.g. from_amount("10.50") => 1050.
      # Parsing goes through BigDecimal so "0.1" means exactly 0.1.
      def from_amount(amount)
        new((BigDecimal(amount.to_s) * 100).round)
      end

      def zero
        new(0)
      end
    end

    def initialize(cents)
      unless cents.is_a?(Integer)
        raise ArgumentError, "cents must be an Integer, got #{cents.inspect}"
      end

      @cents = cents
      freeze
    end

    def +(other) = self.class.new(cents + cents_of(other))
    def -(other) = self.class.new(cents - cents_of(other))
    def -@ = self.class.new(-cents)

    # Scaling money only makes sense by a whole number (e.g. 3 shares).
    def *(factor)
      raise ArgumentError, "factor must be an Integer" unless factor.is_a?(Integer)

      self.class.new(cents * factor)
    end

    def <=>(other) = cents <=> cents_of(other)

    def abs = self.class.new(cents.abs)
    def zero? = cents.zero?
    def positive? = cents.positive?
    def negative? = cents.negative?

    def to_i = cents
    def to_s = format

    # Renders the amount in Brazilian Real style: R$ 1.234,56
    def format(symbol: "R$")
      whole, fraction = cents.abs.divmod(100)
      grouped = whole.to_s.reverse.scan(/\d{1,3}/).join(".").reverse
      "#{"-" if negative?}#{symbol} #{grouped},#{fraction.to_s.rjust(2, "0")}"
    end

    def eql?(other) = other.is_a?(Money) && other.cents == cents
    def hash = cents.hash

    private

    def cents_of(other)
      return other.cents if other.is_a?(Money)
      return other if other.is_a?(Integer)

      raise ArgumentError, "cannot combine Money with #{other.inspect}"
    end
  end
end
