# Base class for all domain services.
#
# A service owns a single use case and is the only place where orchestration
# of domain rules, repositories and side effects should live.
#
# Convention:
#   * one public class method `.call`
#   * returns the domain value on success, raises an Errors::* on failure
#   * all persistence goes through a repository
class ApplicationService
  def self.call(**kwargs)
    new(**kwargs).call
  end

  private

  # Runs a dry-validation contract against the given input and raises a
  # Errors::ValidationError when the input is invalid.
  def validate(contract, input)
    result = contract.call(input)

    return result.to_h if result.success?

    raise Errors::ValidationError.new("Validation failed", details: flatten_errors(result.errors.to_h))
  end

  def flatten_errors(errors)
    errors.flat_map do |key, messages|
      Array(messages).map { |message| "#{key} #{message}" }
    end
  end
end
