class InvitationAcceptancesController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :set_tenant
  skip_before_action :check_onboarding

  layout "application"

  def show
    @invitation = Invitation.find_by!(token: params[:token])

    if @invitation.accepted?
      redirect_to new_user_session_path, notice: "This invitation has already been accepted. Please sign in."
      return
    end

    if @invitation.expired?
      render :expired
      return
    end

    # Check if email is already registered on another account
    existing_user = User.find_by(email: @invitation.email)
    if existing_user && existing_user.account_id != @invitation.account_id
      @error = "This email is already associated with another workspace. Please contact your admin."
      render :expired
      return
    end

    @account = @invitation.account
    @user = User.new(email: @invitation.email)
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Invalid invitation link."
  end

  def update
    @invitation = Invitation.find_by!(token: params[:token])

    if @invitation.accepted? || @invitation.expired?
      redirect_to new_user_session_path, alert: "This invitation is no longer valid."
      return
    end

    @account = @invitation.account
    ActsAsTenant.current_tenant = @account

    @user = @account.users.new(
      email: @invitation.email,
      name: params[:user][:name],
      password: params[:user][:password],
      password_confirmation: params[:user][:password_confirmation],
      role: @invitation.role,
      confirmed_at: Time.current,
      onboarding_completed_at: Time.current,
      onboarding_step: 3
    )

    if @user.save
      @invitation.accept!(@user)
      sign_in(@user)
      redirect_to root_path, notice: "Welcome to #{@account.name}!"
    else
      render :show, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Invalid invitation link."
  end
end
