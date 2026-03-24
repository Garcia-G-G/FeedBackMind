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
    source_type = params.dig(:source, :source_type)
    config_data = params.dig(:source, :config)&.to_unsafe_h || {}

    @source = current_account.sources.find_or_initialize_by(source_type: source_type)
    @source.active = true
    @source.config = (@source.config || {}).merge(config_data)

    if @source.save
      redirect_to @source, notice: "#{source_type.to_s.titleize} source added successfully."
    else
      redirect_to new_source_path, alert: @source.errors.full_messages.join(", ")
    end
  end

  def destroy
    @source.destroy
    redirect_to sources_url, notice: "Source was successfully deleted."
  end

  private

  def set_source
    @source = current_account.sources.find(params[:id])
  end
end
