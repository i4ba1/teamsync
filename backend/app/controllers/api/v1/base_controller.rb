module Api
  module V1
    class BaseController < ApplicationController
      private

      def require_team_membership!
        @team = Team.find_by!(slug: params[:team_id] || params[:id])
        
        unless current_user.member_of?(@team)
          render json: { error: "Forbidden", message: "You are not a member of this team" }, status: :forbidden
        end
      end

      def require_team_admin!
        @team = Team.find_by!(slug: params[:team_id] || params[:id])
        
        unless current_user.admin_of?(@team)
          render json: { error: "Forbidden", message: "Admin access required" }, status: :forbidden
        end
      end

      def require_team_owner!
        @team = Team.find_by!(slug: params[:team_id] || params[:id])
        
        unless current_user.owner_of?(@team)
          render json: { error: "Forbidden", message: "Owner access required" }, status: :forbidden
        end
      end
    end
  end
end
