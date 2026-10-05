# Lightweight result object returned by services.
#
# Usage:
#   ServiceResult.success(user)
#   ServiceResult.failure("Invalid credentials")
class ServiceResult
  attr_reader :value, :error, :details

  def initialize(success:, value: nil, error: nil, details: nil)
    @success = success
    @value = value
    @error = error
    @details = details
  end

  def self.success(value = nil)
    new(success: true, value: value)
  end

  def self.failure(error, details: nil)
    new(success: false, error: error, details: details)
  end

  def success?
    @success
  end

  def failure?
    !@success
  end

  def on_success
    yield value if success?
    self
  end

  def on_failure
    yield(error, details) if failure?
    self
  end
end
