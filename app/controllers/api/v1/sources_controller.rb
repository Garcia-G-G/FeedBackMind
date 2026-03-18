module Api
  module V1
    class SourcesController < BaseController
      before_action :set_source, only: [:show, :update, :destroy]

      # GET /api/v1/sources
      def index
        sources = current_account.sources.order(created_at: :desc)
        sources = sources.where(active: true) if params[:active] == "true"
        sources = sources.where(source_type: params[:source_type]) if params[:source_type].present?

        render json: {
          sources: paginate(sources).map { |s| source_json(s) },
          meta: pagination_meta(sources)
        }
      end

      # GET /api/v1/sources/:id
      def show
        render json: source_json(@source)
      end

      # POST /api/v1/sources
      def create
        source = current_account.sources.create!(source_params)
        render json: source_json(source), status: :created
      end

      # PATCH /api/v1/sources/:id
      def update
        @source.update!(source_params)
        render json: source_json(@source)
      end

      # DELETE /api/v1/sources/:id
      def destroy
        @source.destroy!
        head :no_content
      end

      private

      def set_source
        @source = current_account.sources.find(params[:id])
      end

      def source_params
        params.require(:source).permit(:source_type, :active, config: {})
      end

      def source_json(source)
        {
          id: source.id,
          source_type: source.source_type,
          active: source.active,
          config: source.config,
          last_synced_at: source.last_synced_at,
          created_at: source.created_at,
          updated_at: source.updated_at
        }
      end
    end
  end
end
