module Api
  module V1
    class StandupsController < BaseController
      before_action :require_team_membership!
      before_action :set_standup, only: [:show, :update, :destroy]
      before_action :require_standup_owner!, only: [:update, :destroy]

      def index
        standups = ::Standups::ListStandups.call(
          team: @team,
          filters: standup_filters,
          page: params[:page],
          per_page: params[:per_page]
        )

        render json: StandupSerializer.new(standups, { include: [:user, :standup_items] }).serializable_hash.merge(
          meta: pagination_meta(standups)
        )
      end

      def today
        standup = ::Standups::FindOrInitializeToday.call(team: @team, user: current_user)

        render json: StandupSerializer.new(standup, { include: [:standup_items] }).serializable_hash
      end

      def show
        render json: StandupSerializer.new(@standup, {
          include: [:standup_items, :user]
        }).serializable_hash
      end

      def create
        standup = ::Standups::UpsertStandup.call(
          team: @team,
          user: current_user,
          attributes: standup_params
        )

        render json: StandupSerializer.new(standup, { include: [:standup_items] }).serializable_hash, status: :created
      end

      def update
        standup = ::Standups::UpsertStandup.call(
          team: @team,
          user: current_user,
          attributes: standup_params,
          record: @standup
        )

        render json: StandupSerializer.new(standup, { include: [:standup_items] }).serializable_hash
      end

      def destroy
        ::Standups::DeleteStandup.call(standup: @standup)
        head :no_content
      end

      private

      def set_standup
        @standup = StandupRepository.find!(@team, params[:id])
      end

      def require_standup_owner!
        return if @standup.user == current_user || current_user.admin_of?(@team)

        raise Errors::ForbiddenError, "You can only modify your own standups"
      end

      def standup_params
        params.permit(:standup_date, :status, :submit, items: [:item_type, :content, :order]).to_h.symbolize_keys
      end

      def standup_filters
        {
          start_date: params[:start_date],
          end_date: params[:end_date],
          date: params[:date],
          user_id: params[:user_id],
          status: params[:status]
        }
      end
    end
  end
end
