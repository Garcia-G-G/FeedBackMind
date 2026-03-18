FactoryBot.define do
  factory :chat_message do
    account
    user
    role { :user }
    content { Faker::Lorem.question }

    trait :assistant do
      role { :assistant }
      source_feedback_ids { [1, 2, 3] }
    end
  end
end
