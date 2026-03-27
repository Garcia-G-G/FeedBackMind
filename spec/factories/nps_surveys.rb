FactoryBot.define do
  factory :nps_survey do
    account
    name { "#{Faker::Company.buzzword.titleize} NPS" }
    question { "How likely are you to recommend us?" }
  end
end
