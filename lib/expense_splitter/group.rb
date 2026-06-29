# frozen_string_literal: true

module ExpenseSplitter
  # An aggregate of members and the expenses shared between them. This is the
  # main entry point of the domain: add members, record expenses, then ask
  # for balances or an optimized settlement plan.
  class Group
    attr_reader :id, :name

    def initialize(id:, name:)
      raise ValidationError, "group name can't be blank" if name.to_s.strip.empty?

      @id = id
      @name = name
      @members = {}
      @expenses = []
    end

    def add_member(member)
      @members[member.id] = member
      member
    end

    def add_expense(expense)
      assert_known!(expense.payer_id)
      expense.participant_ids.each { |participant_id| assert_known!(participant_id) }
      @expenses << expense
      expense
    end

    def member(id)
      @members.fetch(id) { raise UnknownMemberError, "unknown member: #{id}" }
    end

    def members = @members.values
    def expenses = @expenses.dup

    # { member_id => Money } net balance per member.
    def balances
      Balance.new(members: members, expenses: @expenses).net
    end

    # Array<Settlement> minimizing the number of transfers.
    def settlements
      SettlementOptimizer.new(balances).call
    end

    private

    def assert_known!(member_id)
      return if @members.key?(member_id)

      raise UnknownMemberError, "unknown member: #{member_id}"
    end
  end
end
