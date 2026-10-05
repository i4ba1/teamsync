class TeamRepository < ApplicationRepository
  class << self
    def find_by_slug!(slug)
      Team.find_by!(slug: slug)
    end

    def for_user(user)
      user.teams.includes(:team_memberships, :created_by)
    end

    def build_for(user, attributes)
      team = user.owned_teams.build(attributes)
      team.created_by = user
      team
    end

    def update(team, attributes)
      team.update(attributes)
    end

    def destroy(team)
      team.destroy!
    end

    def clear_invite_code(team)
      team.clear_invite_code!
    end

    def each(&block)
      Team.find_each(&block)
    end
  end
end
