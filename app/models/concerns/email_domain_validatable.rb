module EmailDomainValidatable
  extend ActiveSupport::Concern

  KNOWN_DOMAINS = %w[
    gmail.com hotmail.com outlook.com yahoo.com icloud.com
    aol.com protonmail.com mail.com zoho.com yandex.com live.com msn.com
  ].freeze

  TYPO_CORRECTIONS = {
    "gamail.com" => "gmail.com", "gmai.com" => "gmail.com", "gmial.com" => "gmail.com",
    "gmaill.com" => "gmail.com", "gnail.com" => "gmail.com", "gmal.com" => "gmail.com",
    "gamil.com" => "gmail.com", "gmaik.com" => "gmail.com", "gmeil.com" => "gmail.com",
    "hotmial.com" => "hotmail.com", "hotmal.com" => "hotmail.com", "hotmai.com" => "hotmail.com",
    "htmail.com" => "hotmail.com", "hotamil.com" => "hotmail.com", "hotmil.com" => "hotmail.com",
    "outlok.com" => "outlook.com", "outllook.com" => "outlook.com", "outlool.com" => "outlook.com",
    "outloo.com" => "outlook.com", "outlookk.com" => "outlook.com",
    "yaho.com" => "yahoo.com", "yahooo.com" => "yahoo.com", "yhaoo.com" => "yahoo.com",
    "tahoo.com" => "yahoo.com", "yhoo.com" => "yahoo.com",
    "icloudd.com" => "icloud.com", "iclod.com" => "icloud.com", "icoud.com" => "icloud.com"
  }.freeze

  included do
    validate :check_email_domain_typo, if: -> { email.present? && email_changed? }
  end

  private

  def check_email_domain_typo
    return unless email.include?("@")
    domain = email.split("@").last&.downcase
    return if domain.blank?

    if TYPO_CORRECTIONS.key?(domain)
      correct_domain = TYPO_CORRECTIONS[domain]
      corrected_email = email.sub(/@.*\z/, "@#{correct_domain}")
      errors.add(:email, "looks like a typo. Did you mean #{corrected_email}?")
    end
  end
end
