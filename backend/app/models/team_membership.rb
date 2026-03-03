class TeamMembership < ApplicationRecord
  # Associations
  belongs_to :team
  belongs_to :user

  # Enums
  enum role: {
    member: 0,
    admin: 1,
    owner: 2
  }, _prefix: true

  # Validations
  validates :user_id, uniqueness: { scope: :team_id, message: "is already a member of this team" }
  validates :joined_at, presence: true
  validate :cannot_change_owner_role, on: :update

  # Callbacks
  before_validation :set_joined_at, on: :create
  after_create :notify_user_added
  after_destroy :notify_user_removed

  # Scopes
  scope :by_role, ->(role) { where(role: role) }
  scope :owners, -> { where(role: :owner) }
  scope :admins, -> { where(role: [:owner, :admin]) }
  scope :recent, -> { order(joined_at: :desc) }

  # Methods
  def promote_to_admin!
    update!(role: :admin)
  end

  def demote_to_member!
    return if role_owner?

    update!(role: :member)
  end

  def transfer_ownership!(new_owner)
    return unless role_owner?

    transaction do
      team.team_memberships.find_by!(user: new_owner).update!(role: :owner)
      update!(role: :admin)
    end
  end

  private

  def set_joined_at
    self.joined_at ||= Time.current
  end

  def cannot_change_owner_role
    if role_changed? && role_was == "owner" && TeamMembership.where(team: team, role: :owner).count == 1
      errors.add(:role, "cannot be changed - team must have at least one owner")
    end
  end

  def notify_user_added
    Notification.create_team_invite(user, team) unless user == team.created_by
  end

  def notify_user_removed
    Notification.create_team_removed(user, team)
  end
end
