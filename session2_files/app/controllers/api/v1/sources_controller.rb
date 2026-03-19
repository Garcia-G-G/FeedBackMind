class Api::V1::SourcesController < Api::V1::BaseController
  before_action :find_source, only: [:show, :update, :destroy, :activate, :deactivate]

  def index
    sources = current_account.sources.order(created_at: :desc)
    sources = sources.where(active: true) if params[:active] == "true"
    sources = sources.where(source_type: params[:type]) if params[:type].present?

    render json: {
      sources: sources.map { |s| source_json(s) }
    }
  end

  def show
    render json: { source: source_json(@source) }
  end

  def create
    source = current_account.sources.build(source_params)

    if source.save
      render json: { source: source_json(source) }, status: :created
    else
      render json: { error: source.errors.full_messages.join(", "), code: "validation_error" }, status: :unprocessable_entity
    end
  end

  def update
    if @source.update(source_params)
      render json: { source: source_json(@source) }
    else
      render json: { error: @source.errors.full_messages.join(", "), code: "validation_error" }, status: :unprocessable_entity
    end
  end

  def destroy
    @source.destroy!
    head :no_content
  end

  def activate
    @source.update!(active: true)
    render json: { source: source_json(@source) }
  end

  def deactivate
    @source.update!(active: false)
    render json: { source: source_json(@source) }
  end

  private

  def find_source
    @source = current_account.sources.find(params[:id])
  end

  def source_params
    params.require(:source).permit(:source_type, config: {})
  end

  def source_json(source)
    {
      id: source.id,
      source_type: source.source_type,
      active: source.active,
      last_synced_at: source.last_synced_at,
      feedbacks_count: source.feedbacks.count,
      webhook_url: webhooks_url_for(source),
      created_at: source.created_at
    }
  end

  def webhooks_url_for(source)
    type = source.source_type
    return nil if %w[csv appstore playstore].include?(type)
    "/webhooks/#{type}?account_id=#{current_account.id}"
  end
end
