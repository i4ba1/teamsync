module Api
  module V1
    class TeamMembersController < BaseController
      before_action :require_team_membership!
      before_action :require_team_admin!, only: [:destroy, :update_role]

      # GET /api/v1/teams/:team_id/members
      def index
        members = @team.team_memberships.includes(:user).order(role: :desc, joined_at: :asc)
        
        render json: TeamMembershipSerializer.new(members).serializable_hash
      end

      # DELETE /api/v1/teams/:team_id/members/:id
      def destroy
        membership = @team.team_memberships.find_by!(user_id: params[:id])
        
        if membership.user == current_user
          render json: { error: "You cannot remove yourself from the team" }, status: :unprocessable_entity
          return
        end

        if membership.role_owner? && @team.team_memberships.where(role: :owner).count == 1
          render json: { error: "Cannot remove the only owner of the team" }, status: :unprocessable_entity
          return
        end

        membership.destroy!
        head :no_content
      end

      # PATCH /api/v1/teams/:team_id/members/:id/update_role
      def update_role
        membership = @team.team_memberships.find_by!(user_id: params[:id])
        new_role = params[:role]

        unless TeamMembership.roles.keys.include?(new_role)
          render json: { error: "Invalid role" }, status: :unprocessable_entity
          return
        end

        # Only owners can assign owner role
        if new_role == "owner" && !current_user.owner_of?(@team)
          render json: { error: "Only owners can transfer ownership" }, status: :forbidden
          return
        end

        if new_role == "owner" && membership.user != current_user
          begin
            membership.transfer_ownership!(current_user)
            render json: { message: "Ownership transferred successfully" }
            return
          rescue => e
            render json: { error: e.message }, status: :unprocessable_entity
            return
          end
        end

        if membership.update(role: new_role)
          render json: TeamMembershipSerializer.new(membership).serializable_hash
        else
          render json: { error: membership.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end
end
