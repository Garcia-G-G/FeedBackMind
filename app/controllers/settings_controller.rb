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

  def invite_member
    unless current_user.owner?
      redirect_to settings_path, alert: "Only owners can invite members."
      return
    end

    max_users = current_account.max_users
    current_count = current_account.users.count

    if max_users != Float::INFINITY && current_count >= max_users
      redirect_to settings_path, alert: "User limit reached for your plan (#{max_users}). Please upgrade."
      return
    end

    email = params[:email]&.strip&.downcase
    if email.blank? || !email.match?(Devise.email_regexp)
      redirect_to settings_path, alert: "Please enter a valid email address."
      return
    end

    if current_account.users.exists?(email: email)
      redirect_to settings_path, alert: "This user is already a member."
      return
    end

    temp_password = SecureRandom.hex(16)
    user = current_account.users.build(
      email: email,
      name: email.split("@").first.titleize,
      password: temp_password,
      password_confirmation: temp_password,
      role: :member
    )

    if user.save
      user.send_reset_password_instructions
      redirect_to settings_path, notice: "Invitation sent to #{email}."
    else
      redirect_to settings_path, alert: "Could not invite user: #{user.errors.full_messages.join(', ')}"
    end
  end

  def remove_member
    unless current_user.owner?
      redirect_to settings_path, alert: "Only owners can remove members."
      return
    end

    member = current_account.users.find(params[:user_id])

    if member == current_user
      redirect_to settings_path, alert: "You cannot remove yourself."
      return
    end

    member.destroy
    redirect_to settings_path, notice: "Team member removed."
  end

  private

  def account_params
    params.require(:account).permit(:name, :plan)
  end
end
