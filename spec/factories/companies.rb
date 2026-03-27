FactoryBot.define do
  factory :company do
    account
    name { Faker::Company.name }
    domain { Faker::Internet.domain_name }
    segment { Company::SEGMENTS.sample }
  end
end
