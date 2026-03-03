FactoryBot.define do
  factory :standup_item do
    association :standup
    content { "Sample standup item content" }
    sort_order { 0 }

    trait :yesterday do
      item_type { :yesterday }
    end

    trait :today do
      item_type { :today }
    end

    trait :blockers do
      item_type { :blockers }
    end

    trait :notes do
      item_type { :notes }
    end
  end
end
