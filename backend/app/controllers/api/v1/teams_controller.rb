module Api
  module V1
    class TeamsController < BaseController
      before_action :require_team_membership!, only: [:show, :update, :destroy, :invite, :join]
      before_action :require_team_admin!, only: [:update, :invite]
      before_action :require_team_owner!, only: [:destroy]

      # GET /api/v1/teams
      def index
        teams = current_user.teams.includes(:team_memberships, :created_by)
        
        render json: TeamSerializer.new(teams, { params: { current_user: current_user } }).serializable_hash
      end

      # GET /api/v1/teams/:slug
      def show
        render json: TeamSerializer.new(@team, { 
          params: { current_user: current_user },
          include: [:members]
        }).serializable_hash
      end

      # POST /api/v1/teams
      def create
        team = current_user.owned_teams.build(team_params)
        team.created_by = current_user

        if team.save
          render json: TeamSerializer.new(team).serializable_hash, status: :created
        else
          render json: { error: team.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PUT /api/v1/teams/:slug
      def update
        if @team.update(team_params)
          render json: TeamSerializer.new(@team).serializable_hash
        else
          render json: { error: @team.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/teams/:slug
      def destroy
        @team.destroy!
        head :no_content
      end

      # POST /api/v1/teams/:slug/invite
      def invite
        user = User.find_by(email: params[:email]&.downcase)
        
        if user.nil?
          # TODO: Send invitation email for new user
          render json: { error: "User not found" }, status: :not_found
          return
        end

        if user.member_of?(@team)
          render json: { error: "User is already a member of this team" }, status: :unprocessable_entity
          return
        end

        membership = @team.team_memberships.create(
          user: user,
          role: params[:role] || :member,
          joined_at: Time.current
        )

        if membership.persisted?
          render json: { message: "Invitation sent successfully" }, status: :created
        else
          render json: { error: membership.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/teams/:slug/join
      def join
        if params[:invite_code].present?
          unless @team.invite_code_valid? && @team.invite_code == params[:invite_code].upcase
            render json: { error: "Invalid or expired invite code" }, status: :unprocessable_entity
            return
          end
        end

        if current_user.member_of?(@team)
          render json: { error: "You are already a member of this team" }, status: :unprocessable_entity
          return
        end

        membership = @team.team_memberships.create(
          user: current_user,
          role: :member,
          joined_at: Time.current
        )

        if membership.persisted?
          @team.clear_invite_code! if params[:invite_code].present?
          render json: TeamSerializer.new(@team).serializable_hash, status: :created
        else
          render json: { error: membership.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def team_params
        params.require(:team).permit(:name, :timezone, :standup_time, standup_days: [])
      end
    end
  end
end
