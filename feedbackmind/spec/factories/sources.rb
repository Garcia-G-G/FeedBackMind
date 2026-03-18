FactoryBot.define do
  factory :source do
    account
    source_type { :intercom }
    active { true }
    config { { "api_key" => "test_key_123" } }

    trait :inactive do
      active { false }
    end

    Source.source_types.keys.each do |type|
      trait type.to_sym do
        source_type { type }
      end
    end
  end
end
