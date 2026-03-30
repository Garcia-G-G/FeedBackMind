FactoryBot.define do
  factory :invitation do
    account
    association :invited_by, factory: :user
    email { Faker::Internet.unique.email }
    role { :member }
  end
end
