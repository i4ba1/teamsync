module Notifications
  class ListNotifications < ApplicationService
    CONTRACT = ListNotificationsContract.new

    def initialize(user:, filters:, page: nil, per_page: nil)
      @user = user
      @filters = filters
      @page = page
      @per_page = per_page
    end

    def call
      attrs = validate(CONTRACT, @filters)
      scope = NotificationRepository.for_user(@user)
      scope = NotificationRepository.filter(
        scope,
        unread: attrs[:unread] == "true",
        read: attrs[:read] == "true"
      )

      NotificationRepository.paginate(scope, @page || 1, @per_page || 20)
    end
  end
end
