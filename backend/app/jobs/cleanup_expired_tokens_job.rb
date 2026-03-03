class CleanupExpiredTokensJob < ApplicationJob
  queue_as :default

  def perform
    # Delete expired refresh tokens older than 30 days
    RefreshToken.where("expires_at < ?", 30.days.ago).destroy_all
    
    # Also clean up revoked tokens older than 7 days
    RefreshToken.where.not(revoked_at: nil)
                .where("revoked_at < ?", 7.days.ago)
                .destroy_all
    
    Rails.logger.info("Cleaned up expired refresh tokens")
  end
end
