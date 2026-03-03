FactoryBot.define do
  factory :standup do
    association :team
    association :user
    standup_date { Date.current }
    status { :draft }

    trait :submitted do
      status { :submitted }
      completed_at { Time.current }
    end

    trait :missed do
      status { :missed }
    end

    trait :vacation do
      status { :vacation }
    end

    trait :with_items do
      after(:create) do |standup|
        create(:standup_item, :yesterday, standup: standup)
        create(:standup_item, :today, standup: standup)
        create(:standup_item, :blockers, standup: standup)
      end
    end
  end
end
