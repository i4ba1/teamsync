FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    first_name { "John" }
    last_name { "Doe" }
    timezone { "UTC" }
    status { :active }
    role { :member }

    trait :admin do
      role { :admin }
    end

    trait :super_admin do
      role { :super_admin }
    end

    trait :inactive do
      status { :inactive }
    end

    trait :suspended do
      status { :suspended }
    end
  end
end
