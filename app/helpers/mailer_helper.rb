module MailerHelper
  def status_bg_color(status)
    case status
    when "open" then "#dbeafe"
    when "planned" then "#ede9fe"
    when "in_progress" then "#fef3c7"
    when "shipped" then "#d1fae5"
    when "declined" then "#f5f5f4"
    else "#f5f5f4"
    end
  end

  def status_text_color(status)
    case status
    when "open" then "#1d4ed8"
    when "planned" then "#6d28d9"
    when "in_progress" then "#b45309"
    when "shipped" then "#047857"
    when "declined" then "#78716c"
    else "#78716c"
    end
  end
end
