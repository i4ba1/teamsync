class PresenceChannel < ApplicationCable::Channel
  def subscribed
    @team = Team.find_by(slug: params[:team_slug])
    
    if @team.nil? || !current_user.member_of?(@team)
      reject
      return
    end

    stream_for @team
    
    # Mark user as online
    set_online_status(true)
    
    # Broadcast user joined
    broadcast_user_status("online")
    
    # Send current online users
    transmit({
      type: "presence_state",
      users: online_users
    })
  end

  def unsubscribed
    return unless @team.present?
    
    # Mark user as offline
    set_online_status(false)
    
    # Broadcast user left
    broadcast_user_status("offline")
  end

  def receive(data)
    case data["action"]
    when "ping"
      # Update last seen timestamp
      update_last_seen
      transmit({ type: "pong", timestamp: Time.current.iso8601 })
    when "get_online_users"
      transmit({
        type: "online_users",
        users: online_users
      })
    end
  end

  private

  def set_online_status(online)
    Redis.current.hset(presence_key, current_user.id, {
      user_id: current_user.id,
      full_name: current_user.full_name,
      online: online,
      last_seen: Time.current.iso8601
    }.to_json)
    
    # Set expiration for offline users
    unless online
      Redis.current.hdel(presence_key, current_user.id)
    end
  end

  def update_last_seen
    data = Redis.current.hget(presence_key, current_user.id)
    return unless data

    parsed = JSON.parse(data)
    parsed["last_seen"] = Time.current.iso8601
    Redis.current.hset(presence_key, current_user.id, parsed.to_json)
  end

  def broadcast_user_status(status)
    PresenceChannel.broadcast_to(@team, {
      type: "presence_update",
      user: {
        id: current_user.id,
        full_name: current_user.full_name,
        status: status
      }
    })
  end

  def online_users
    users_data = Redis.current.hgetall(presence_key)
    users_data.values.map { |data| JSON.parse(data) }.select { |u| u["online"] }
  end

  def presence_key
    "presence:team:#{@team.id}"
  end
end
