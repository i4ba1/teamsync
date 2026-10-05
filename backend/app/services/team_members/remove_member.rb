module TeamMembers
  class RemoveMember < ApplicationService
    def initialize(team:, current_user:, user_id:)
      @team = team
      @current_user = current_user
      @user_id = user_id
    end

    def call
      membership = TeamMembershipRepository.find_by_user_id!(@team, @user_id)

      if membership.user == @current_user
        raise Errors::ValidationError, "You cannot remove yourself from the team"
      end

      if membership.role_owner? && TeamMembershipRepository.owner_count(@team) == 1
        raise Errors::ValidationError, "Cannot remove the only owner of the team"
      end

      TeamMembershipRepository.destroy(membership)
    end
  end
end
