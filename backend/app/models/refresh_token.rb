class RefreshToken < ApplicationRecord
  belongs_to :user

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  before_validation :set_expires_at, on: :create

  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }
  scope :revoked, -> { where.not(revoked_at: nil) }

  def self.generate_for(user, device_info: nil)
    token = SecureRandom.base64(32)
    digest = Digest::SHA256.hexdigest(token)
    
    refresh_token = create!(
      user: user,
      token_digest: digest,
      device_info: device_info
    )
    
    [token, refresh_token]
  end

  def self.find_by_token(token)
    return nil if token.blank?
    
    digest = Digest::SHA256.hexdigest(token)
    find_by(token_digest: digest)
  end

  def active?
    revoked_at.nil? && expires_at > Time.current
  end

  def expired?
    expires_at <= Time.current
  end

  def revoked?
    revoked_at.present?
  end

  def revoke!
    update!(revoked_at: Time.current) unless revoked?
  end

  private

  def set_expires_at
    self.expires_at ||= 30.days.from_now
  end
end
