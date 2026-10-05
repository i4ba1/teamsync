class Notification < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :team, optional: true

  # Enums
  enum notification_type: {
    standup_reminder: 0,
    mention: 1,
    team_invite: 2,
    standup_submitted: 3,
    team_removed: 4,
    role_changed: 5,
    standup_summary: 6
  }, _prefix: true

  # Validations
  validates :title, presence: true, length: { maximum: 255 }
  validates :message, presence: true
  validates :notification_type, presence: true

  # Callbacks
  after_create_commit :broadcast_notification

  # Scopes
  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_user, ->(user) { where(user: user) }

  # Class methods
  def self.create_standup_reminder(user, team)
    return unless user.status_active?

    create!(
      user: user,
      team: team,
      notification_type: :standup_reminder,
      title: "Standup Reminder",
      message: "Your standup for #{team.name} is due soon!",
      data: { team_slug: team.slug, standup_date: Date.current.to_s }
    )
  end

  def self.create_team_invite(user, team)
    create!(
      user: user,
      team: team,
      notification_type: :team_invite,
      title: "Team Invitation",
      message: "You've been added to the team '#{team.name}'",
      data: { team_slug: team.slug }
    )
  end

  def self.create_team_removed(user, team)
    create!(
      user: user,
      team: team,
      notification_type: :team_removed,
      title: "Removed from Team",
      message: "You've been removed from the team '#{team.name}'",
      data: { team_name: team.name }
    )
  end

  def self.create_standup_submitted(user, standup)
    create!(
      user: user,
      team: standup.team,
      notification_type: :standup_submitted,
      title: "New Standup Submitted",
      message: "#{standup.user.full_name} submitted their standup for #{standup.team.name}",
      data: {
        team_slug: standup.team.slug,
        standup_id: standup.id,
        user_name: standup.user.full_name
      }
    )
  end

  def self.create_mention(user, standup, mentioner)
    create!(
      user: user,
      team: standup.team,
      notification_type: :mention,
      title: "You were mentioned",
      message: "#{mentioner.full_name} mentioned you in their standup",
      data: {
        team_slug: standup.team.slug,
        standup_id: standup.id
      }
    )
  end

  def self.mark_all_as_read!(user)
    where(user: user, read_at: nil).update_all(read_at: Time.current)
  end

  # Instance methods
  def read!
    update!(read_at: Time.current) unless read?
  end

  def read?
    read_at.present?
  end

  def unread?
    !read?
  end

  def as_json(options = {})
    super(options.merge(methods: [:read?])).tap do |hash|
      hash["read"] = hash.delete("read?")
    end
  end

  private

  def broadcast_notification
    NotificationChannel.broadcast_to(user, {
      type: "new_notification",
      notification: NotificationSerializer.new(self).serializable_hash
    })
  end
end
