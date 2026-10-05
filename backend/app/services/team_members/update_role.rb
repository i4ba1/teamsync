module TeamMembers
  class UpdateRole < ApplicationService
    CONTRACT = UpdateRoleContract.new

    def initialize(team:, current_user:, user_id:, role:)
      @team = team
      @current_user = current_user
      @user_id = user_id
      @role = role
    end

    def call
      attrs = validate(CONTRACT, role: @role)
      new_role = attrs[:role]

      membership = TeamMembershipRepository.find_by_user_id!(@team, @user_id)

      unless TeamMembership.roles.keys.include?(new_role)
        raise Errors::ValidationError, "Invalid role"
      end

      if new_role == "owner" && !@current_user.owner_of?(@team)
        raise Errors::ForbiddenError, "Only owners can transfer ownership"
      end

      if new_role == "owner" && membership.user != @current_user
        TeamMembershipRepository.transfer_ownership!(membership, @current_user)
        return { membership: membership, transferred: true }
      end

      unless TeamMembershipRepository.update_role(membership, new_role)
        raise Errors::ValidationError.new("Validation failed", details: membership.errors.full_messages)
      end

      { membership: membership, transferred: false }
    end
  end
end
