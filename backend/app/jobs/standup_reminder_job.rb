class StandupReminderJob < ApplicationJob
  queue_as :default

  def perform
    Standups::SendReminders.call
  end
end
