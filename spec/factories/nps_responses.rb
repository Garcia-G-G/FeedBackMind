FactoryBot.define do
  factory :nps_response do
    nps_survey
    account
    score { rand(0..10) }
    comment { Faker::Lorem.sentence }
    respondent_email { Faker::Internet.email }
  end
end
