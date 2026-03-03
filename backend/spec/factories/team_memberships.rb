FactoryBot.define do
  factory :team_membership do
    association :team
    association :user
    role { :member }
    joined_at { Time.current }

    trait :owner do
      role { :owner }
    end

    trait :admin do
      role { :admin }
    end
  end
end
