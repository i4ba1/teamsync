module Api
  module V1
    class NotificationsController < ApplicationController

      def index
        notifications = current_user.notifications
          .includes(:team)
          .order(created_at: :desc)
        
        # Filter by read status
        if params[:unread] == "true"
          notifications = notifications.unread
        elsif params[:read] == "true"
          notifications = notifications.read
        end
        
        # Pagination
        notifications = notifications.page(params[:page] || 1).per(params[:per_page] || 20)
        
        render json: NotificationSerializer.new(notifications).serializable_hash.merge(
          meta: {
            unread_count: current_user.unread_notifications_count,
            pagination: pagination_meta(notifications)
          }
        )
      end

      # GET /api/v1/notifications/:id
      def show
        notification = current_user.notifications.find(params[:id])
        notification.read! unless notification.read?
        
        render json: NotificationSerializer.new(notification).serializable_hash
      end

      # PATCH /api/v1/notifications/:id
      def update
        notification = current_user.notifications.find(params[:id])
        
        if params[:read] == true
          notification.read!
        end
        
        render json: NotificationSerializer.new(notification).serializable_hash
      end

      # POST /api/v1/notifications/mark_all_read
      def mark_all_read
        Notification.mark_all_as_read!(current_user)
        
        render json: { message: "All notifications marked as read", unread_count: 0 }
      end
    end
  end
end
