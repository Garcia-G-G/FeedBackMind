FactoryBot.define do
  factory :user do
    account
    email { Faker::Internet.unique.email }
    password { "password123!" }
    role { :owner }
    onboarding_completed_at { Time.current }
    onboarding_step { 3 }

    trait :member do
      role { :member }
    end

    trait :unonboarded do
      onboarding_completed_at { nil }
      onboarding_step { 0 }
    end
  end
end
