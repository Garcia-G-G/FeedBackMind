class SettingsController < ApplicationController
  def show
    @account = current_account
  end

  def regenerate_token
    current_account.regenerate_api_token!
    redirect_to settings_path, notice: "API token regenerated."
  end

  def update
    @account = current_account

    if @account.update(account_params)
      redirect_to settings_path, notice: 'Settings were successfully updated.'
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def account_params
    params.require(:account).permit(:name, :plan)
  end
end
