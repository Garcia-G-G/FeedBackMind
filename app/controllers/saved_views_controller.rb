class SavedViewsController < ApplicationController
  def create
    @view = current_account.saved_views.new(saved_view_params)
    @view.user = current_user

    if @view.save
      redirect_to feedbacks_path(@view.filters), notice: "View \"#{@view.name}\" saved."
    else
      redirect_to feedbacks_path, alert: @view.errors.full_messages.join(", ")
    end
  end

  def destroy
    view = current_account.saved_views.find(params[:id])
    view.destroy
    redirect_to feedbacks_path, notice: "View deleted."
  end

  private

  def saved_view_params
    params.require(:saved_view).permit(:name, :icon, filters: {})
  end
end
