Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
  
  # Schedule recurring jobs
  config.on(:startup) do
    Sidekiq.schedule = {
      "standup_reminder_job" => {
        "cron" => "0 * * * *",
        "class" => "StandupReminderJob",
        "queue" => "default"
      },
      "mark_missed_standups_job" => {
        "cron" => "0 0 * * *",
        "class" => "MarkMissedStandupsJob",
        "queue" => "default"
      }
    }
    SidekiqScheduler::Scheduler.instance.reload_schedule!
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end
