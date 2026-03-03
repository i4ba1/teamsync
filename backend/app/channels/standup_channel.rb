class StandupChannel < ApplicationCable::Channel
  def subscribed
    team = Team.find_by(slug: params[:team_slug])
    
    if team.nil?
      reject
      return
    end

    unless current_user.member_of?(team)
      reject
      return
    end

    @team = team
    stream_for team
    
    # Also stream to the user's personal updates for this team
    stream_from "user:#{current_user.id}:team:#{team.id}"
    
    # Send initial state
    transmit({
      type: "connected",
      message: "Subscribed to standup updates for #{team.name}",
      team_id: team.id,
      team_slug: team.slug
    })
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    stop_all_streams
  end

  def receive(data)
    # Handle incoming messages from client
    case data["action"]
    when "ping"
      transmit({ type: "pong", timestamp: Time.current.iso8601 })
    when "get_standups"
      send_standups(data)
    end
  end

  def self.broadcast_standup_update(standup)
    broadcast_to(standup.team, {
      type: "standup_updated",
      standup: StandupSerializer.new(standup).serializable_hash
    })
  end

  def self.broadcast_standup_created(standup)
    broadcast_to(standup.team, {
      type: "standup_created",
      standup: StandupSerializer.new(standup).serializable_hash
    })
  end

  def self.broadcast_standup_deleted(standup)
    broadcast_to(standup.team, {
      type: "standup_deleted",
      standup_id: standup.id,
      user_id: standup.user_id
    })
  end

  def self.broadcast_standup_reminder(team, user)
    broadcast_to(team, {
      type: "standup_reminder",
      message: "Standup is due for #{user.full_name}",
      user_id: user.id
    })
  end

  private

  def send_standups(data)
    date = data["date"] || Date.current.to_s
    standups = @team.standups.for_date(date).includes(:user, :standup_items)
    
    transmit({
      type: "standups_list",
      date: date,
      standups: StandupSerializer.new(standups).serializable_hash
    })
  end
end
