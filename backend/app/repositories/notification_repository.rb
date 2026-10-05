class NotificationRepository < ApplicationRepository
  class << self
    def for_user(user)
      user.notifications.includes(:team).order(created_at: :desc)
    end

    def filter(scope, unread: false, read: false)
      return scope.unread if unread
      return scope.read if read

      scope
    end

    def paginate(scope, page, per_page)
      scope.page(page).per(per_page)
    end

    def find_for_user!(user, id)
      user.notifications.find(id)
    end

    def unread_count(user)
      user.unread_notifications_count
    end

    def mark_all_read(user)
      Notification.mark_all_as_read!(user)
    end

    def create(attributes)
      Notification.create!(attributes)
    end
  end
end
