# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/expense_splitter"

module ExpenseSplitter
  # Shared base so individual test files can use Money, Group, etc. without
  # the ExpenseSplitter:: prefix everywhere.
  class TestCase < Minitest::Test
    include ExpenseSplitter

    private

    # Builds a group pre-populated with named members. Returns [group, ids]
    # where ids maps the friendly name to the generated member id.
    def group_with(*names)
      repo = Repository.new
      group = repo.create_group(name: "Test Group")
      ids = names.to_h do |name|
        member = Member.new(id: repo.next_id("mbr"), name: name.to_s)
        group.add_member(member)
        [name, member.id]
      end
      [group, ids]
    end
  end
end
