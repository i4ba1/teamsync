module RefreshTokens
  class CleanupExpired < ApplicationService
    def call
      RefreshTokenRepository.cleanup_expired
      RefreshTokenRepository.cleanup_revoked

      Rails.logger.info("Cleaned up expired refresh tokens")
    end
  end
end
