# frozen_string_literal: true

require "json"
require "bigdecimal"

# ExpenseSplitter - a zero-dependency Ruby backend for splitting group
# expenses and computing the minimal set of payments to settle up.
#
# The public surface is small: build a Group, add Members and Expenses
# (each with a split strategy), then read #balances or #settlements.
module ExpenseSplitter
end

require_relative "expense_splitter/version"
require_relative "expense_splitter/errors"
require_relative "expense_splitter/money"
require_relative "expense_splitter/member"
require_relative "expense_splitter/splits/apportionment"
require_relative "expense_splitter/splits/base_split"
require_relative "expense_splitter/splits/equal_split"
require_relative "expense_splitter/splits/exact_split"
require_relative "expense_splitter/splits/percentage_split"
require_relative "expense_splitter/splits/share_split"
require_relative "expense_splitter/splits/factory"
require_relative "expense_splitter/expense"
require_relative "expense_splitter/balance"
require_relative "expense_splitter/settlement"
require_relative "expense_splitter/settlement_optimizer"
require_relative "expense_splitter/group"
require_relative "expense_splitter/repository"
require_relative "expense_splitter/api/router"
require_relative "expense_splitter/api/serializer"
require_relative "expense_splitter/api/application"
require_relative "expense_splitter/api/server"
