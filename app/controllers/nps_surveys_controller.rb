class NpsSurveysController < ApplicationController
  before_action :set_survey, only: [:show, :edit, :update, :destroy, :toggle_active]

  def index
    @surveys = current_account.nps_surveys.order(created_at: :desc)
  end

  def show
    @breakdown = @survey.nps_breakdown
    @recent_responses = @survey.nps_responses.recent.limit(20)
    @score_distribution = @survey.nps_responses.group(:score).count
  end

  def new
    @survey = current_account.nps_surveys.new
  end

  def create
    @survey = current_account.nps_surveys.new(survey_params)

    if @survey.save
      redirect_to nps_survey_path(@survey), notice: "NPS survey created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @survey.update(survey_params)
      redirect_to nps_survey_path(@survey), notice: "NPS survey updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @survey.destroy
    redirect_to nps_surveys_path, notice: "NPS survey deleted."
  end

  def toggle_active
    @survey.update!(active: !@survey.active?)
    status = @survey.active? ? "activated" : "paused"
    redirect_to nps_survey_path(@survey), notice: "Survey #{status}."
  end

  private

  def set_survey
    @survey = current_account.nps_surveys.find(params[:id])
  end

  def survey_params
    params.require(:nps_survey).permit(:name, :question, :followup_question, :thank_you_message, :brand_color, :position)
  end
end
