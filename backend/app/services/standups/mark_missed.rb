module Standups
  # Marks yesterday's missing standups as missed and flags drafts as missed.
  # Invoked by MarkMissedStandupsJob.
  class MarkMissed < ApplicationService
    def call
      yesterday = Date.current - 1.day

      TeamRepository.each do |team|
        next unless team.standup_due_on?(yesterday)

        members_with_standup = StandupRepository.for_date(team, yesterday).pluck(:user_id)
        all_member_ids = team.team_memberships.pluck(:user_id)
        missing_member_ids = all_member_ids - members_with_standup

        missing_member_ids.each do |user_id|
          StandupRepository.create(
            team: team,
            user_id: user_id,
            standup_date: yesterday,
            status: :missed
          )
        end

        StandupRepository.for_date(team, yesterday).where(status: :draft).find_each do |standup|
          standup.update!(status: :missed)
        end
      end
    end
  end
end
