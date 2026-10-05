module Auth
  class RegisterUser < ApplicationService
    CONTRACT = RegisterUserContract.new

    def initialize(attributes:, device_info: nil)
      @attributes = attributes
      @device_info = device_info
    end

    def call
      attrs = validate(CONTRACT, @attributes)
      user = UserRepository.create(attrs)

      unless user.persisted?
        raise Errors::ValidationError.new("Validation failed", details: user.errors.full_messages)
      end

      {
        user: user,
        tokens: PasetoService.generate_tokens(user, device_info: @device_info)
      }
    end
  end
end
