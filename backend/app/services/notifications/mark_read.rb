module Notifications
  class MarkRead < ApplicationService
    def initialize(user:, id:)
      @user = user
      @id = id
    end

    def call
      notification = NotificationRepository.find_for_user!(@user, @id)
      notification.read! unless notification.read?
      notification
    end
  end
end
