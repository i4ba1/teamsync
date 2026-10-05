module Standups
  # Builds and delivers the daily standup summary to team admins/owners.
  # Invoked by DailySummaryJob.
  class BuildDailySummaries < ApplicationService
    def call
      yesterday = Date.current - 1.day

      TeamRepository.each do |team|
        next unless team.standup_due_on?(yesterday)

        standups = StandupRepository.for_date(team, yesterday)
        submitted_count = standups.where(status: :submitted).count
        missed_count = standups.where(status: :missed).count
        total_members = team.member_count

        team.team_memberships.where(role: [:owner, :admin]).find_each do |membership|
          NotificationRepository.create(
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
end
