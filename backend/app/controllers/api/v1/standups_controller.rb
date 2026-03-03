module Api
  module V1
    class StandupsController < BaseController
      before_action :require_team_membership!
      before_action :set_standup, only: [:show, :update, :destroy]
      before_action :require_standup_owner!, only: [:update, :destroy]

      def index
        standups = @team.standups
          .includes(:user, :standup_items)
          .order(standup_date: :desc, created_at: :desc)
        
        # Filter by date range
        if params[:start_date].present? && params[:end_date].present?
          standups = standups.for_date_range(params[:start_date], params[:end_date])
        elsif params[:date].present?
          standups = standups.for_date(params[:date])
        end
        
        # Filter by user
        if params[:user_id].present?
          standups = standups.where(user_id: params[:user_id])
        end
        
        # Filter by status
        if params[:status].present?
          standups = standups.where(status: params[:status])
        end
        
        # Pagination
        standups = standups.page(params[:page] || 1).per(params[:per_page] || 20)
        
        render json: StandupSerializer.new(standups, { include: [:standup_items] }).serializable_hash.merge(
          meta: pagination_meta(standups)
        )
      end

      # GET /api/v1/teams/:team_id/standups/today
      def today
        standup = Standup.find_or_initialize_by(
          team: @team,
          user: current_user,
          standup_date: Date.current
        )
        
        render json: StandupSerializer.new(standup, { include: [:standup_items] }).serializable_hash
      end

      # GET /api/v1/teams/:team_id/standups/:id
      def show
        render json: StandupSerializer.new(@standup, { 
          include: [:standup_items, :user]
        }).serializable_hash
      end

      # POST /api/v1/teams/:team_id/standups
      def create
        standup = Standup.find_or_initialize_by(
          team: @team,
          user: current_user,
          standup_date: params[:standup_date] || Date.current
        )
        
        items_params = standup_params[:items] || []
        
        if params[:submit] == true
          begin
            standup.submit!(items_params)
            render json: StandupSerializer.new(standup, { include: [:standup_items] }).serializable_hash, status: :created
          rescue ActiveRecord::RecordInvalid => e
            render json: { error: e.message }, status: :unprocessable_entity
          end
        else
          standup.status = :draft
          
          if standup.save
            standup.update_items(items_params) if items_params.present?
            render json: StandupSerializer.new(standup, { include: [:standup_items] }).serializable_hash, status: :created
          else
            render json: { error: standup.errors.full_messages }, status: :unprocessable_entity
          end
        end
      end

      # PUT /api/v1/teams/:team_id/standups/:id
      def update
        items_params = standup_params[:items] || []
        
        if params[:submit] == true
          begin
            @standup.submit!(items_params)
            render json: StandupSerializer.new(@standup, { include: [:standup_items] }).serializable_hash
          rescue ActiveRecord::RecordInvalid => e
            render json: { error: e.message }, status: :unprocessable_entity
          end
        else
          if items_params.present?
            @standup.update_items(items_params)
          end
          
          if @standup.update(status: params[:status] || @standup.status)
            render json: StandupSerializer.new(@standup, { include: [:standup_items] }).serializable_hash
          else
            render json: { error: @standup.errors.full_messages }, status: :unprocessable_entity
          end
        end
      end

      # DELETE /api/v1/teams/:team_id/standups/:id
      def destroy
        @standup.destroy!
        head :no_content
      end

      private

      def set_standup
        @standup = @team.standups.find(params[:id])
      end

      def require_standup_owner!
        unless @standup.user == current_user || current_user.admin_of?(@team)
          render json: { error: "Forbidden", message: "You can only modify your own standups" }, status: :forbidden
        end
      end

      def standup_params
        params.permit(
          :standup_date, :status, :submit,
          items: [:item_type, :content, :order]
        )
      end
    end
  end
end
