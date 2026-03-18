FactoryBot.define do
  factory :account do
    name { Faker::Company.name }
    subdomain { Faker::Internet.slug(glue: "-") }
    plan { :starter }
    feedback_count_this_month { 0 }

    trait :growth do
      plan { :growth }
    end

    trait :scale do
      plan { :scale }
    end

    trait :with_stripe do
      stripe_customer_id { "cus_#{SecureRandom.hex(8)}" }
      stripe_subscription_id { "sub_#{SecureRandom.hex(8)}" }
    end
  end
end
