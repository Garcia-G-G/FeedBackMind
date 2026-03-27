FactoryBot.define do
  factory :feature_request do
    account
    title { Faker::Lorem.sentence(word_count: 5) }
    description { Faker::Lorem.paragraph }
    author_email { Faker::Internet.email }
    author_name { Faker::Name.name }
    status { :open }

    trait :published do
      published_at { Time.current }
    end

    trait :shipped do
      status { :shipped }
      shipped_at { Time.current }
      published_at { 1.week.ago }
    end
  end
end
