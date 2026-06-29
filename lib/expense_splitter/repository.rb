# frozen_string_literal: true

module ExpenseSplitter
  # In-memory store and id authority for the API layer. Swapping this for a
  # database-backed implementation would not touch the domain objects - they
  # don't know or care where they're persisted.
  class Repository
    def initialize
      @groups = {}
      @sequence = 0
    end

    def create_group(name:)
      group = Group.new(id: next_id("grp"), name: name)
      @groups[group.id] = group
    end

    def group(id)
      @groups.fetch(id) { raise NotFoundError, "group not found: #{id}" }
    end

    def next_id(prefix)
      @sequence += 1
      "#{prefix}_#{@sequence}"
    end
  end
end
