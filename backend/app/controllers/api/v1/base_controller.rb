module Api
  module V1
    class BaseController < ApplicationController
      private

      def load_team!
        @team ||= TeamRepository.find_by_slug!(team_slug_param)
      end

      # Nested routes use :team_slug, collection/member routes use :slug.
      def team_slug_param
        params[:team_slug] || params[:slug] || params[:team_id] || params[:id]
      end

      def require_team_membership!
        load_team!

        unless current_user.member_of?(@team)
          raise Errors::ForbiddenError, "You are not a member of this team"
        end
      end

      def require_team_admin!
        load_team!

        unless current_user.admin_of?(@team)
          raise Errors::ForbiddenError, "Admin access required"
        end
      end

      def require_team_owner!
        load_team!

        unless current_user.owner_of?(@team)
          raise Errors::ForbiddenError, "Owner access required"
        end
      end
    end
  end
end
