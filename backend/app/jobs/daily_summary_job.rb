class DailySummaryJob < ApplicationJob
  queue_as :default

  def perform
    # Send daily summary to team owners/admins
    Team.find_each do |team|
      yesterday = Date.current - 1.day
      
      # Skip if yesterday was not a standup day
      next unless team.standup_due_on?(yesterday)
      
      # Get standup stats
      standups = team.standups.where(standup_date: yesterday)
      submitted_count = standups.where(status: :submitted).count
      missed_count = standups.where(status: :missed).count
      total_members = team.member_count
      
      # Find admin users
      admin_memberships = team.team_memberships.where(role: [:owner, :admin])
      
      admin_memberships.find_each do |membership|
        Notification.create!(
          user: membership.user,
          team: team,
          notification_type: :standup_summary,
          title: "Daily Standup Summary",
          message: "Yesterday: #{submitted_count}/#{total_members} standups submitted, #{missed_count} missed",
          data: {
            date: yesterday.to_s,
            submitted: submitted_count,
            missed: missed_count,
            total: total_members,
            team_slug: team.slug
          }
        )
      end
    end
  end
end
