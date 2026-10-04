module Api
  module V1
    class TeamMembersController < BaseController
      before_action :require_team_membership!
      before_action :require_team_admin!, only: [:destroy, :update_role]

      def index
        members = TeamMembershipRepository.with_users(@team)

        render json: TeamMembershipSerializer.new(members, { include: [:user] }).serializable_hash
      end

      def destroy
        ::TeamMembers::RemoveMember.call(team: @team, current_user: current_user, user_id: params[:id])
        head :no_content
      end

      def update_role
        result = ::TeamMembers::UpdateRole.call(
          team: @team,
          current_user: current_user,
          user_id: params[:id],
          role: params[:role]
        )

        if result[:transferred]
          render json: { message: "Ownership transferred successfully" }
        else
          render json: TeamMembershipSerializer.new(result[:membership]).serializable_hash
        end
      end
    end
  end
end
