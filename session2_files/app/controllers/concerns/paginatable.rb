module Paginatable
  extend ActiveSupport::Concern

  private

  def page
    [params.fetch(:page, 1).to_i, 1].max
  end

  def per_page
    [params.fetch(:per_page, 25).to_i, 100].min
  end

  def paginate(scope)
    scope.offset((page - 1) * per_page).limit(per_page)
  end

  def pagination_meta(scope)
    total = scope.count
    {
      current_page: page,
      per_page: per_page,
      total_count: total,
      total_pages: (total.to_f / per_page).ceil
    }
  end
end
