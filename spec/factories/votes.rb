FactoryBot.define do
  factory :vote do
    feature_request
    account
    voter_email { Faker::Internet.email }
    voter_name { Faker::Name.name }
  end
end
