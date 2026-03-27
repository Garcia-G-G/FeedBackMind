class FeatureRequestMailer < ApplicationMailer
  def status_update(feature_request, voter_email)
    @feature_request = feature_request
    @account = feature_request.account
    @status_label = feature_request.status.titleize

    mail(
      to: voter_email,
      subject: "[#{@account.name}] \"#{feature_request.title}\" is now #{@status_label}"
    )
  end
end
