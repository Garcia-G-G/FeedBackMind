FactoryBot.define do
  factory :feedback do
    account
    source
    content { Faker::Lorem.paragraph(sentence_count: 3) }
    received_at { Faker::Time.between(from: 1.week.ago, to: Time.current) }

    trait :processed do
      sentiment { [:positive, :neutral, :negative].sample }
      topics { Faker::Lorem.words(number: 3).map(&:downcase) }
      processed_at { Time.current }
      # Note: embedding would need to be set manually or via a mock
    end

    trait :unprocessed do
      sentiment { nil }
      topics { [] }
      processed_at { nil }
      embedding { nil }
    end

    trait :positive do
      sentiment { :positive }
    end

    trait :negative do
      sentiment { :negative }
    end
  end
end
