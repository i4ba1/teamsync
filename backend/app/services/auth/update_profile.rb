module Auth
  class UpdateProfile < ApplicationService
    CONTRACT = UpdateProfileContract.new

    def initialize(user:, attributes:)
      @user = user
      @attributes = attributes
    end

    def call
      attrs = validate(CONTRACT, @attributes)

      unless UserRepository.update(@user, attrs)
        raise Errors::ValidationError.new("Validation failed", details: @user.errors.full_messages)
      end

      @user
    end
  end
end
