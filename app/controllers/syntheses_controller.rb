class SynthesesController < ApplicationController
  before_action :set_synthesis, only: [:show]

  def index
    @syntheses = current_account.weekly_syntheses.order(week_start: :desc)
  end

  def show
  end

  def new
    @synthesis = current_account.weekly_syntheses.build
  end

  def create
    unless ENV["OPENAI_API_KEY"].present?
      redirect_to syntheses_path, alert: "OpenAI API key is not configured. Please set OPENAI_API_KEY in your environment."
      return
    end

    week_start = Date.current.beginning_of_week(:monday)
    if current_account.weekly_syntheses.exists?(week_start: week_start)
      redirect_to syntheses_path, alert: "A synthesis for this week already exists."
      return
    end

    unless current_account.feedbacks.processed.last_7_days.any?
      redirect_to syntheses_path, alert: "No processed feedbacks from the last 7 days to analyze."
      return
    end

    WeeklySynthesisJob.perform_async(current_account.id)
    redirect_to syntheses_path, notice: "Weekly synthesis is being generated. Please check back in a minute."
  end

  private

  def set_synthesis
    @synthesis = current_account.weekly_syntheses.find(params[:id])
  end
end
