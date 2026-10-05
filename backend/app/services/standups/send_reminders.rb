module Standups
  # Sends standup reminders to team members whose standup is due and not yet
  # submitted. Invoked by StandupReminderJob.
  class SendReminders < ApplicationService
    def call
      TeamRepository.each do |team|
        next unless team.standup_due_today?

        standup_due_time = team.standup_time_in_zone
        current_time_in_zone = Time.current.in_time_zone(team.timezone)

        next unless should_send_reminder?(current_time_in_zone, standup_due_time)

        members_to_remind = team.members.active.where.not(id: StandupRepository.submitted_user_ids(team))

        members_to_remind.find_each do |user|
          Notification.create_standup_reminder(user, team)
          StandupChannel.broadcast_standup_reminder(team, user)
        end
      end
    end

    private

    def should_send_reminder?(current_time, standup_time)
      diff = (standup_time - current_time) / 60

      [60, 30, 10].any? { |window| diff.between?(window - 5, window + 5) }
    end
  end
end
