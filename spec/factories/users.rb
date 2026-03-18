FactoryBot.define do
  factory :user do
    account
    email { Faker::Internet.unique.email }
    password { "password123!" }
    role { :owner }

    trait :member do
      role { :member }
    end
  end
end
