module Api
  module V1
    class NotificationsController < ApplicationController
      def index
        notifications = ::Notifications::ListNotifications.call(
          user: current_user,
          filters: notification_filters,
          page: params[:page],
          per_page: params[:per_page]
        )

        render json: NotificationSerializer.new(notifications, { include: [:team] }).serializable_hash.merge(
          meta: {
            unread_count: NotificationRepository.unread_count(current_user),
            pagination: pagination_meta(notifications)
          }
        )
      end

      def show
        notification = ::Notifications::MarkRead.call(user: current_user, id: params[:id])

        render json: NotificationSerializer.new(notification).serializable_hash
      end

      def update
        if params[:read] == true
          notification = ::Notifications::MarkRead.call(user: current_user, id: params[:id])
        else
          notification = NotificationRepository.find_for_user!(current_user, params[:id])
        end

        render json: NotificationSerializer.new(notification).serializable_hash
      end

      def mark_all_read
        ::Notifications::MarkAllRead.call(user: current_user)

        render json: { message: "All notifications marked as read", unread_count: 0 }
      end

      private

      def notification_filters
        { unread: params[:unread], read: params[:read] }
      end
    end
  end
end
