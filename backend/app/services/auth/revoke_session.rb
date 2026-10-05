module Auth
  class RevokeSession < ApplicationService
    def initialize(refresh_token:)
      @refresh_token = refresh_token
    end

    def call
      PasetoService.revoke_refresh_token(@refresh_token) if @refresh_token.present?
      true
    end
  end
end
