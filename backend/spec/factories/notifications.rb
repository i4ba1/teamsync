FactoryBot.define do
  factory :notification do
    association :user
    association :team
    notification_type { :standup_reminder }
    title { "Test Notification" }
    message { "This is a test notification" }
    data { {} }

    trait :read do
      read_at { Time.current }
    end

    trait :team_invite do
      notification_type { :team_invite }
      title { "Team Invitation" }
    end
  end
end
