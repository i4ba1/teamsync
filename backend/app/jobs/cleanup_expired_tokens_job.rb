class CleanupExpiredTokensJob < ApplicationJob
  queue_as :default

  def perform
    RefreshTokens::CleanupExpired.call
  end
end
