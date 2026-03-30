class InvitationMailer < ApplicationMailer
  def invite(invitation)
    @invitation = invitation
    @account = invitation.account
    @inviter = invitation.invited_by

    mail(
      to: invitation.email,
      subject: "You've been invited to join #{@account.name} on FeedbackMind"
    )
  end
end
