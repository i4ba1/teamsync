class NotificationChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user
    
    # Send initial unread count
    transmit({
      type: "connected",
      message: "Subscribed to notifications",
      unread_count: current_user.unread_notifications_count
    })
  end

  def unsubscribed
    stop_all_streams
  end

  def receive(data)
    case data["action"]
    when "ping"
      transmit({ type: "pong", timestamp: Time.current.iso8601 })
    when "mark_read"
      mark_notification_read(data["notification_id"])
    when "mark_all_read"
      mark_all_notifications_read
    end
  end

  def self.broadcast_notification(user, notification)
    broadcast_to(user, {
      type: "new_notification",
      notification: NotificationSerializer.new(notification).serializable_hash
    })
  end

  def self.broadcast_unread_count(user)
    broadcast_to(user, {
      type: "unread_count",
      count: user.unread_notifications_count
    })
  end

  private

  def mark_notification_read(notification_id)
    notification = current_user.notifications.find_by(id: notification_id)
    return unless notification

    notification.read!
    
    transmit({
      type: "notification_marked_read",
      notification_id: notification_id,
      unread_count: current_user.unread_notifications_count
    })
  end

  def mark_all_notifications_read
    Notification.mark_all_as_read!(current_user)
    
    transmit({
      type: "all_notifications_marked_read",
      unread_count: 0
    })
  end
end
