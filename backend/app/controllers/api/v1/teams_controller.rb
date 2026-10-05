module Api
  module V1
    class TeamsController < BaseController
      before_action :require_team_membership!, only: [:show, :update, :destroy, :invite]
      before_action :require_team_admin!, only: [:update, :invite]
      before_action :require_team_owner!, only: [:destroy]
      # Non-members may join via an invite code, so only load the team.
      before_action :load_team!, only: [:join]

      def index
        teams = ::Teams::ListUserTeams.call(user: current_user)

        render json: TeamSerializer.new(teams, { params: { current_user: current_user } }).serializable_hash
      end

      def show
        render json: TeamSerializer.new(@team, {
          params: { current_user: current_user },
          include: [:members]
        }).serializable_hash
      end

      def create
        team = ::Teams::CreateTeam.call(user: current_user, attributes: team_params)

        render json: TeamSerializer.new(team).serializable_hash, status: :created
      end

      def update
        team = ::Teams::UpdateTeam.call(team: @team, attributes: team_params)

        render json: TeamSerializer.new(team).serializable_hash
      end

      def destroy
        ::Teams::DeleteTeam.call(team: @team)
        head :no_content
      end

      def invite
        ::Teams::InviteMember.call(team: @team, email: params[:email], role: params[:role])

        render json: { message: "Invitation sent successfully" }, status: :created
      end

      def join
        team = ::Teams::JoinTeam.call(team: @team, user: current_user, invite_code: params[:invite_code])

        render json: TeamSerializer.new(team).serializable_hash, status: :created
      end

      private

      def team_params
        params.require(:team).permit(:name, :timezone, :standup_time, standup_days: []).to_h.symbolize_keys
      end
    end
  end
end
