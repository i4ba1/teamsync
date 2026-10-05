module Auth
  class AuthenticateUser < ApplicationService
    CONTRACT = AuthenticateUserContract.new

    def initialize(attributes:, device_info: nil)
      @attributes = attributes
      @device_info = device_info
    end

    def call
      attrs = validate(CONTRACT, @attributes)
      user = UserRepository.active_by_email(attrs[:email])

      unless user&.authenticate(attrs[:password])
        raise Errors::UnauthorizedError, "Invalid email or password"
      end

      {
        user: user,
        tokens: PasetoService.generate_tokens(user, device_info: @device_info)
      }
    end
  end
end
