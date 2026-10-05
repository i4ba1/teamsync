class RefreshTokenRepository < ApplicationRepository
  class << self
    def generate_for(user, device_info: nil)
      RefreshToken.generate_for(user, device_info: device_info)
    end

    def find_by_token(token)
      RefreshToken.find_by_token(token)
    end

    def revoke(token)
      refresh_token = find_by_token(token)
      return false if refresh_token.nil?

      refresh_token.revoke!
      true
    end

    def cleanup_expired(before: 30.days.ago)
      RefreshToken.where("expires_at < ?", before).destroy_all
    end

    def cleanup_revoked(before: 7.days.ago)
      RefreshToken.where.not(revoked_at: nil).where("revoked_at < ?", before).destroy_all
    end
  end
end
