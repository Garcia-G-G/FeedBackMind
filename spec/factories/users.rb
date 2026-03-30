FactoryBot.define do
  factory :user do
    account
    email { Faker::Internet.unique.email }
    password { "password123!" }
    password_confirmation { "password123!" }
    name { Faker::Name.name }
    role { :owner }
    onboarding_completed_at { Time.current }
    onboarding_step { 3 }
    confirmed_at { Time.current }

    trait :member do
      role { :member }
    end

    trait :unonboarded do
      onboarding_completed_at { nil }
      onboarding_step { 0 }
    end
  end
end
