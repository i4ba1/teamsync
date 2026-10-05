class Standup < ApplicationRecord
  # Associations
  belongs_to :team
  belongs_to :user
  has_many :standup_items, dependent: :destroy

  # Enums
  enum status: {
    draft: 0,
    submitted: 1,
    missed: 2,
    vacation: 3,
    holiday: 4
  }, _prefix: true

  # Validations
  validates :standup_date, presence: true
  validates :user_id, uniqueness: { scope: :standup_date, message: "already has a standup for this date" }
  validate :standup_date_cannot_be_in_future
  validate :user_must_be_team_member

  # Callbacks
  before_validation :set_standup_date, on: :create
  after_save :broadcast_standup_update, if: :saved_change_to_status?
  after_create :notify_standup_created

  # Scopes
  scope :for_date, ->(date) { where(standup_date: date) }
  scope :for_date_range, ->(start_date, end_date) { where(standup_date: start_date..end_date) }
  scope :for_team, ->(team) { where(team: team) }
  scope :for_user, ->(user) { where(user: user) }
  scope :recent, -> { order(standup_date: :desc) }
  scope :submitted_or_missed, -> { where(status: [:submitted, :missed]) }
  scope :completed, -> { where(status: :submitted) }

  # Class methods
  def self.today
    for_date(Date.current)
  end

  def self.find_or_initialize_today(team, user)
    find_or_initialize_by(team: team, user: user, standup_date: Date.current)
  end

  # Instance methods
  # Submission and item management are handled by Standups::UpsertStandup.
  def items_by_type
    standup_items.order(:sort_order).group_by(&:item_type)
  end

  def yesterday_items
    standup_items.where(item_type: :yesterday).order(:sort_order)
  end

  def today_items
    standup_items.where(item_type: :today).order(:sort_order)
  end

  def blockers
    standup_items.where(item_type: :blockers).order(:sort_order)
  end

  def notes
    standup_items.where(item_type: :notes).order(:sort_order)
  end

  def editable?
    status_draft? || (status_submitted? && standup_date >= 7.days.ago.to_date)
  end

  def to_summary
    {
      id: id,
      user: user.full_name,
      date: standup_date,
      status: status,
      completed_at: completed_at,
      items_count: standup_items.count
    }
  end

  private

  def set_standup_date
    self.standup_date ||= Date.current
  end

  def standup_date_cannot_be_in_future
    return unless standup_date.present? && standup_date > Date.current

    errors.add(:standup_date, "cannot be in the future")
  end

  def user_must_be_team_member
    return unless team.present? && user.present?

    unless team.members.exists?(id: user.id)
      errors.add(:user, "must be a member of the team")
    end
  end

  def broadcast_standup_update
    StandupChannel.broadcast_to(team, {
      type: "standup_updated",
      standup: StandupSerializer.new(self).serializable_hash
    })
  end

  def notify_standup_created
    return unless status_submitted?

    team.members.where.not(id: user.id).find_each do |member|
      Notification.create_standup_submitted(member, self)
    end
  end
end
