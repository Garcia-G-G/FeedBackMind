class InvitationsController < ApplicationController
  include Authorizable
  before_action :authorize_owner!

  def index
    @users = current_account.users.order(:role, :created_at)
    @pending_invitations = current_account.invitations.pending.order(created_at: :desc)
    @accepted_invitations = current_account.invitations.accepted.order(accepted_at: :desc).limit(10)
  end

  def create
    @invitation = current_account.invitations.new(invitation_params)
    @invitation.invited_by = current_user

    # Prevent inviting as owner
    if @invitation.role.to_s == "owner"
      redirect_to invitations_path, alert: "Cannot invite as owner."
      return
    end

    # Check if email is registered on another account
    if User.exists?(email: @invitation.email) && !current_account.users.exists?(email: @invitation.email)
      redirect_to invitations_path, alert: "This email is already registered on another workspace."
      return
    end

    if @invitation.save
      InvitationMailer.invite(@invitation).deliver_later
      redirect_to invitations_path, notice: "Invitation sent to #{@invitation.email}."
    else
      redirect_to invitations_path, alert: @invitation.errors.full_messages.join(", ")
    end
  end

  def destroy
    invitation = current_account.invitations.pending.find(params[:id])
    invitation.destroy
    redirect_to invitations_path, notice: "Invitation revoked."
  end

  private

  def invitation_params
    params.require(:invitation).permit(:email, :role)
  end
end
