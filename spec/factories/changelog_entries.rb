FactoryBot.define do
  factory :changelog_entry do
    account
    title { Faker::Lorem.sentence(word_count: 4) }
    body { Faker::Lorem.paragraphs(number: 2).join("\n\n") }
    category { :new_feature }

    trait :published do
      published_at { Time.current }
    end
  end
end
