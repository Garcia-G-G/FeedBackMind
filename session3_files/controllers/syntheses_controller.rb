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
    WeeklySynthesisJob.perform_later(current_account.id)
    redirect_to syntheses_path, notice: 'Weekly synthesis is being generated. Please check back shortly.'
  end

  private

  def set_synthesis
    @synthesis = current_account.weekly_syntheses.find(params[:id])
  end
end
