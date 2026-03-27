require "rails_helper"

RSpec.describe "NPS Surveys", type: :request do
  let(:account) { create(:account, :growth) }
  let(:user) { create(:user, account: account) }

  before { sign_in_as(user) }

  describe "GET /nps" do
    it "returns 200" do
      get nps_surveys_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /nps" do
    it "creates a survey" do
      expect {
        post nps_surveys_path, params: { nps_survey: { name: "Q1 NPS" } }
      }.to change(NpsSurvey, :count).by(1)
    end
  end

  describe "GET /nps/:id" do
    it "shows survey details" do
      ActsAsTenant.current_tenant = account
      survey = create(:nps_survey, account: account)
      get nps_survey_path(survey)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(survey.name)
    end
  end
end
