class StandupReminderJob < ApplicationJob
  queue_as :default

  def perform
    Team.find_each do |team|
      next unless team.standup_due_today?
      
      # Get the standup due time in team's timezone
      standup_due_time = team.standup_time_in_zone
      current_time_in_zone = Time.current.in_time_zone(team.timezone)
      
      # Check if we're within 1 hour of standup time
      next unless should_send_reminder?(current_time_in_zone, standup_due_time)
      
      # Find members who haven't submitted their standup
      members_to_remind = team.members.active.where.not(
        id: team.today_standups.where(status: :submitted).select(:user_id)
      )
      
      members_to_remind.find_each do |user|
        # Create notification
        Notification.create_standup_reminder(user, team)
        
        # Broadcast via Action Cable
        StandupChannel.broadcast_standup_reminder(team, user)
        
        # TODO: Send email notification if enabled in user preferences
      end
    end
  end

  private

  def should_send_reminder?(current_time, standup_time)
    # Send reminders at 1 hour, 30 minutes, and 10 minutes before standup time
    diff = (standup_time - current_time) / 60 # difference in minutes
    
    # Check if we're within 5 minutes of a reminder window
    [60, 30, 10].any? { |window| diff.between?(window - 5, window + 5) }
  end
end
