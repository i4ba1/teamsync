module Auth
  class RefreshSession < ApplicationService
    CONTRACT = RefreshSessionContract.new

    def initialize(refresh_token:)
      @refresh_token = refresh_token
    end

    def call
      validate(CONTRACT, refresh_token: @refresh_token)

      tokens = PasetoService.refresh_access_token(@refresh_token)
      raise Errors::UnauthorizedError, "Invalid or expired refresh token" if tokens.blank?

      tokens
    end
  end
end
