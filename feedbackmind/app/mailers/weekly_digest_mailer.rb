class WeeklyDigestMailer < ApplicationMailer
  def digest_email(synthesis)
    @synthesis = synthesis
    @account = synthesis.account
    @themes = synthesis.themes
    @risk = synthesis.risk

    mail(
      to: @account.users.pluck(:email),
      subject: "#{@account.name} — Weekly Feedback Digest (#{@synthesis.week_label})"
    )
  end
end
