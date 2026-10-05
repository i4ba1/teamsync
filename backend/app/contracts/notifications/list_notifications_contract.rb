module Notifications
  class ListNotificationsContract < ApplicationContract
    params do
      optional(:unread).maybe(:string)
      optional(:read).maybe(:string)
    end
  end
end
