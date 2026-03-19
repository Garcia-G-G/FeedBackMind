class SourcesController < ApplicationController
  before_action :set_source, only: [:show, :destroy]

  def index
    @sources = current_account.sources.order(:source_type)
  end

  def show
    @feedbacks_count = @source.feedbacks.count
  end

  def new
    @source = current_account.sources.build
  end

  def create
    @source = current_account.sources.build(source_params)

    if @source.save
      redirect_to @source, notice: 'Source was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @source.destroy
    redirect_to sources_url, notice: 'Source was successfully deleted.'
  end

  private

  def set_source
    @source = current_account.sources.find(params[:id])
  end

  def source_params
    params.require(:source).permit(:name, :source_type, credentials: {})
  end
end
