module Paginatable
  extend ActiveSupport::Concern

  DEFAULT_PER_PAGE = 25
  MAX_PER_PAGE = 100

  private

  def page
    [params[:page].to_i, 1].max
  end

  def per_page
    requested = params[:per_page].to_i
    requested = DEFAULT_PER_PAGE if requested <= 0
    [requested, MAX_PER_PAGE].min
  end

  def paginate(scope)
    scope.offset((page - 1) * per_page).limit(per_page)
  end

  def pagination_meta(scope)
    total = scope.count
    {
      page: page,
      per_page: per_page,
      total: total,
      total_pages: (total.to_f / per_page).ceil
    }
  end
end
