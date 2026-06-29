# frozen_string_literal: true

module ExpenseSplitter
  # A person who takes part in a group's expenses.
  class Member
    attr_reader :id, :name

    def initialize(id:, name:)
      raise ValidationError, "member name can't be blank" if name.to_s.strip.empty?

      @id = id
      @name = name
      freeze
    end

    def to_h = { id: id, name: name }
  end
end
