class User < ApplicationRecord
  acts_as_paranoid

  has_secure_password

  # Associations
  has_many :team_memberships, dependent: :destroy
  has_many :teams, through: :team_memberships
  has_many :owned_teams, class_name: "Team", foreign_key: "created_by_id", dependent: :nullify
  has_many :standups, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :refresh_tokens, dependent: :destroy

  # Enums
  enum status: {
    active: 0,
    inactive: 1,
    suspended: 2
  }, _prefix: true

  enum role: {
    member: 0,
    admin: 1,
    super_admin: 2
  }, _prefix: true

  # Validations
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, presence: true, length: { maximum: 50 }
  validates :last_name, presence: true, length: { maximum: 50 }
  validates :timezone, presence: true, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }
  validates :password, length: { minimum: 8 }, if: :password_required?

  # Scopes
  scope :active, -> { where(status: :active) }
  scope :by_team, ->(team_id) { joins(:team_memberships).where(team_memberships: { team_id: team_id }) }

  # Callbacks
  before_validation :downcase_email
  after_create :welcome_notification

  # Methods
  def full_name
    "#{first_name} #{last_name}"
  end

  def initials
    "#{first_name.first}#{last_name.first}".upcase
  end

  def member_of?(team)
    team_memberships.exists?(team: team)
  end

  def admin_of?(team)
    team_memberships.exists?(team: team, role: [:admin, :owner])
  end

  def owner_of?(team)
    team_memberships.exists?(team: team, role: :owner) || team.created_by_id == id
  end

  def today_standup(team)
    standups.find_by(team: team, standup_date: Date.current)
  end

  def unread_notifications_count
    notifications.where(read_at: nil).count
  end

  def active_refresh_tokens
    refresh_tokens.where(revoked_at: nil).where("expires_at > ?", Time.current)
  end

  def revoke_all_tokens!
    refresh_tokens.where(revoked_at: nil).update_all(revoked_at: Time.current)
  end

  private

  def downcase_email
    self.email = email.downcase if email.present?
  end

  def password_required?
    new_record? || password.present?
  end

  def welcome_notification
    # Will be implemented with notification system
  end
end
