FactoryBot.define do
  factory :team do
    sequence(:name) { |n| "Team #{n}" }
    sequence(:slug) { |n| "team-#{n}" }
    timezone { "UTC" }
    standup_time { "09:00" }
    standup_days { [1, 2, 3, 4, 5] }
    settings { { reminder_enabled: true } }
    association :created_by, factory: :user

    trait :with_members do
      after(:create) do |team|
        create_list(:team_membership, 3, team: team)
      end
    end
  end
end
