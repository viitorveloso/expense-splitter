# frozen_string_literal: true

module ExpenseSplitter
  # Base class for every error this library raises on purpose.
  class Error < StandardError; end

  # The caller sent semantically invalid data (maps to HTTP 422).
  class ValidationError < Error; end

  # A split was given inconsistent parameters (e.g. percentages that
  # don't add up to 100). Still a validation problem.
  class SplitError < ValidationError; end

  # A member id was referenced that the group does not know about.
  class UnknownMemberError < Error; end

  # A resource (group, ...) could not be found (maps to HTTP 404).
  class NotFoundError < Error; end
end
