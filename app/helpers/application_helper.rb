module ApplicationHelper
  # Renders a sidebar navigation link with icon and optional badge
  # @param label [String] The display text for the link
  # @param path [String] The URL path for the link
  # @param icon_name [String] SVG icon identifier (dashboard, feedback, syntheses, sources, pipeline, loop_tracker, settings)
  # @param active [Boolean] Whether this link is currently active
  # @param badge [Integer, nil] Optional badge count/text
  # @param badge_warn [Boolean] Whether to use warning color for badge
  def sidebar_link(label, path, icon_name, active, badge: nil, badge_warn: false)
    active_classes = active ? "bg-stone-100 text-stone-900" : "text-stone-700 hover:bg-stone-50"
    icon_svg = render_sidebar_icon(icon_name)

    content_tag :div, class: "relative" do
      link_to path, class: "flex items-center gap-3 px-4 py-3 rounded-lg transition-colors #{active_classes}" do
        content_tag(:span, icon_svg.html_safe, class: "flex-shrink-0 w-5 h-5") +
        content_tag(:span, label, class: "flex-1 text-sm font-medium") +
        (badge.present? ? content_tag(:span, badge, class: "ml-2 px-2 py-0.5 rounded-full text-xs font-semibold #{badge_warn ? 'bg-amber-100 text-amber-700' : 'bg-stone-100 text-stone-700'}") : "")
      end
    end
  end

  # Returns Tailwind color classes for sentiment
  # @param sentiment [String] One of: positive, neutral, negative
  # @return [String] Tailwind CSS classes
  def sentiment_color(sentiment)
    case sentiment&.to_s&.downcase
    when "positive"
      "text-emerald-700"
    when "neutral"
      "text-blue-700"
    when "negative"
      "text-red-700"
    else
      "text-stone-700"
    end
  end

  # Returns Tailwind color classes for urgency level
  # @param urgency [String] One of: critical, high, medium, positive
  # @return [String] Combined background and text classes
  def urgency_color(urgency)
    case urgency&.to_s&.downcase
    when "critical"
      "bg-red-100 text-red-700"
    when "high"
      "bg-amber-100 text-amber-700"
    when "medium"
      "bg-blue-100 text-blue-700"
    when "positive"
      "bg-emerald-100 text-emerald-700"
    else
      "bg-stone-100 text-stone-700"
    end
  end

  # Returns emoji for source type
  # @param source_type [String] One of: intercom, gmail, app_store, typeform, jira, slack, play_store, csv
  # @return [String] Emoji character
  def source_emoji(source_type)
    case source_type&.to_s&.downcase
    when "intercom"
      "💬"
    when "gmail"
      "📧"
    when "app_store"
      "⭐"
    when "typeform"
      "📋"
    when "jira"
      "🔧"
    when "slack"
      "💼"
    when "play_store"
      "📱"
    when "csv"
      "📄"
    when "nps"
      "📊"
    else
      "📌"
    end
  end

  # Formats time as "X days/hours/minutes ago"
  # @param time [Time] The time to format
  # @return [String] Human-readable time difference
  def format_time_ago(time)
    return "Never" if time.blank?

    seconds_ago = ((Time.current - time).to_i).abs
    minutes_ago = seconds_ago / 60
    hours_ago = minutes_ago / 60
    days_ago = hours_ago / 24
    weeks_ago = days_ago / 7
    months_ago = days_ago / 30

    case
    when seconds_ago < 60
      "now"
    when minutes_ago < 60
      "#{minutes_ago}m ago"
    when hours_ago < 24
      "#{hours_ago}h ago"
    when days_ago < 7
      "#{days_ago}d ago"
    when weeks_ago < 4
      "#{weeks_ago}w ago"
    when months_ago < 12
      "#{months_ago}mo ago"
    else
      time.strftime("%b %d, %Y")
    end
  end

  private

  # Renders SVG icon for sidebar based on icon name
  # @param icon_name [String] The identifier for the icon
  # @return [String] SVG markup
  def render_sidebar_icon(icon_name)
    icons = {
      dashboard: '<svg fill="currentColor" viewBox="0 0 20 20"><path d="M10.707 2.293a1 1 0 00-1.414 0l-7 7a1 1 0 001.414 1.414L4 10.414V17a1 1 0 001 1h2a1 1 0 001-1v-2a1 1 0 011-1h2a1 1 0 011 1v2a1 1 0 001 1h2a1 1 0 001-1v-6.586l.293.293a1 1 0 001.414-1.414l-7-7z"/></svg>',
      feedback: '<svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M7 8h10M7 12h4m1 8l-4-4H5a2 2 0 01-2-2V5a2 2 0 012-2h14a2 2 0 012 2v12a2 2 0 01-2 2h-3l-4 4z"/></svg>',
      syntheses: '<svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>',
      sources: '<svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.658 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1"/></svg>',
      pipeline: '<svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M9 19l3 3m0 0l3-3m-3 3v-6"/></svg>',
      loop_tracker: '<svg fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/></svg>',
      requests: '<svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"/></svg>',
      nps: '<svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"/></svg>',
      changelog: '<svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z"/></svg>',
      settings: '<svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"/><path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/></svg>'
    }

    icons[icon_name.to_sym] || icons[:dashboard]
  end
end
