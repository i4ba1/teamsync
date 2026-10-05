module Notifications
  class MarkAllRead < ApplicationService
    def initialize(user:)
      @user = user
    end

    def call
      NotificationRepository.mark_all_read(@user)
    end
  end
end
