FactoryBot.define do
  factory :saved_view do
    account
    user
    name { "My #{Faker::Lorem.word.titleize} View" }
    filters { { sentiment: "negative", sort: "priority" } }
  end
end
