class TeamMembershipRepository < ApplicationRepository
  class << self
    def with_users(team)
      team.team_memberships.includes(:user).order(role: :desc, joined_at: :asc)
    end

    def find_by_user_id!(team, user_id)
      team.team_memberships.find_by!(user_id: user_id)
    end

    def find_for_user(team, user)
      team.team_memberships.find_by(user: user)
    end

    def exists?(team, user)
      team.team_memberships.exists?(user: user)
    end

    def owner_count(team)
      team.team_memberships.where(role: :owner).count
    end

    def create(team, attributes)
      team.team_memberships.create(attributes)
    end

    def update_role(membership, role)
      membership.update(role: role)
    end

    def destroy(membership)
      membership.destroy!
    end

    def transfer_ownership!(membership, new_owner)
      membership.transfer_ownership!(new_owner)
    end
  end
end
