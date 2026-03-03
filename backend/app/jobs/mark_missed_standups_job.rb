class MarkMissedStandupsJob < ApplicationJob
  queue_as :default

  def perform
    yesterday = Date.current - 1.day
    
    Team.find_each do |team|
      # Skip if yesterday was not a standup day for this team
      next unless team.standup_due_on?(yesterday)
      
      # Find members who didn't submit their standup yesterday
      members_with_standup = team.standups.where(standup_date: yesterday).pluck(:user_id)
      all_member_ids = team.team_memberships.pluck(:user_id)
      missing_member_ids = all_member_ids - members_with_standup
      
      # Create missed standup records
      missing_member_ids.each do |user_id|
        Standup.create!(
          team: team,
          user_id: user_id,
          standup_date: yesterday,
          status: :missed
        )
      end
      
      # Mark draft standups as missed
      team.standups.where(standup_date: yesterday, status: :draft).find_each do |standup|
        standup.update!(status: :missed)
      end
    end
  end
end
