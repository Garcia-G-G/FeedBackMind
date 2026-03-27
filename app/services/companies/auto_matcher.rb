module Companies
  class AutoMatcher
    FREE_EMAIL_DOMAINS = %w[
      gmail.com yahoo.com hotmail.com outlook.com aol.com
      icloud.com mail.com protonmail.com zoho.com yandex.com
      live.com msn.com me.com fastmail.com tutanota.com
      gmx.com inbox.com rocketmail.com att.net comcast.net
      verizon.net sbcglobal.net cox.net
    ].freeze

    def initialize(account)
      @account = account
    end

    def match(feedback)
      return unless feedback.author_email.present?
      return if feedback.company_id.present?

      domain = feedback.author_email.split("@").last&.downcase
      return if domain.blank?
      return if FREE_EMAIL_DOMAINS.include?(domain)

      company = @account.companies.find_or_create_by!(domain: domain) do |c|
        c.name = humanize_domain(domain)
      end

      feedback.update_columns(company_id: company.id)
      Company.reset_counters(company.id, :feedbacks)
    end

    def match_all
      matched = 0
      @account.feedbacks.where(company_id: nil).where.not(author_email: [nil, ""]).find_each do |feedback|
        match(feedback)
        matched += 1 if feedback.reload.company_id.present?
      end
      matched
    end

    private

    def humanize_domain(domain)
      domain.sub(/\.\w+$/, "").tr("-_.", " ").split.map(&:capitalize).join(" ")
    end
  end
end
