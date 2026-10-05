module Errors
  # Base class for all domain errors raised by services.
  class ApplicationError < StandardError
    attr_reader :details

    def initialize(message = nil, details: nil)
      @details = details
      super(message)
    end
  end
end
