class Team < ApplicationRecord
  acts_as_paranoid

  # Associations
  belongs_to :created_by, class_name: "User"
  has_many :team_memberships, dependent: :destroy
  has_many :members, through: :team_memberships, source: :user
  has_many :standups, dependent: :destroy
  has_many :notifications, dependent: :destroy

  # Enums
  # No specific enum needed, using integer array for standup_days

  # Validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :slug, presence: true, uniqueness: { case_sensitive: false }, format: { with: /\A[a-z0-9-]+\z/ }
  validates :timezone, presence: true, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }
  validates :standup_days, presence: true
  validate :valid_standup_days

  # Callbacks
  before_validation :generate_slug, on: :create
  before_validation :set_default_standup_time
  after_create :add_creator_as_owner

  # Scopes
  scope :by_member, ->(user) { joins(:team_memberships).where(team_memberships: { user: user }) }

  # Methods
  def to_param
    slug
  end

  def standup_due_today?
    standup_days.include?(Date.current.wday)
  end

  def standup_due_on?(date)
    standup_days.include?(date.wday)
  end

  def standup_time_in_zone
    Time.zone = timezone
    Time.zone.parse(standup_time.strftime("%H:%M"))
  end

  def standup_due_datetime_for(date)
    Time.use_zone(timezone) do
      Time.zone.parse("#{date} #{standup_time.strftime("%H:%M")}")
    end
  end

  def member_count
    team_memberships.count
  end

  def today_standups
    standups.where(standup_date: Date.current)
  end

  def today_submitted_count
    today_standups.where(status: :submitted).count
  end

  def today_missed_count
    today_standups.where(status: :missed).count
  end

  def pending_members_count
    team_memberships.where(role: :pending).count
  end

  def generate_invite_code!(expires_in: 7.days)
    update!(
      invite_code: SecureRandom.alphanumeric(12).upcase,
      invite_code_expires_at: expires_in.from_now
    )
    invite_code
  end

  def clear_invite_code!
    update!(invite_code: nil, invite_code_expires_at: nil)
  end

  def invite_code_valid?
    invite_code.present? && invite_code_expires_at.present? && invite_code_expires_at > Time.current
  end

  def member_role(user)
    team_memberships.find_by(user: user)&.role
  end

  private

  def generate_slug
    return if slug.present?

    base_slug = name.to_s.parameterize
    unique_slug = base_slug
    counter = 1

    while Team.exists?(slug: unique_slug)
      unique_slug = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = unique_slug
  end

  def set_default_standup_time
    self.standup_time ||= Time.parse("09:00")
  end

  def valid_standup_days
    return if standup_days.blank?

    unless standup_days.is_a?(Array) && standup_days.all? { |d| d.is_a?(Integer) && d.between?(0, 6) }
      errors.add(:standup_days, "must be an array of integers 0-6 (Sunday=0, Saturday=6)")
    end
  end

  def add_creator_as_owner
    team_memberships.create!(
      user: created_by,
      role: :owner,
      joined_at: Time.current
    )
  end
end
