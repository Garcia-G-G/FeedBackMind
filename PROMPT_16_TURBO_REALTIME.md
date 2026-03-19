# PROMPT 16 — Turbo Frames + Streams for Real-Time UX

Make the app feel alive with Turbo Frames for fast navigation and Turbo Streams for real-time updates.

## Task 1: Add Turbo Frames to Dashboard

Wrap sections in turbo_frame_tag so period switching updates only the relevant section:

### Dashboard metrics as Turbo Frame
```erb
<%%= turbo_frame_tag "dashboard_metrics", src: dashboard_path(period: @period), loading: :lazy do %>
  <!-- metrics grid -->
<%% end %>
```

When the user clicks a period button (7d, 30d, Quarter), it should update the metrics frame via a Turbo Frame request, not a full page reload.

Update the period_selector Stimulus controller to use Turbo.visit with the frame:
```javascript
select(event) {
  const period = event.target.dataset.period
  const url = new URL(window.location)
  url.searchParams.set("period", period)

  // Use Turbo Frame to update just the metrics
  const frame = document.querySelector("turbo-frame#dashboard_metrics")
  if (frame) {
    frame.src = url.toString()
  }
}
```

### Feedbacks list as Turbo Frame
Wrap the feedbacks list in:
```erb
<%%= turbo_frame_tag "feedbacks_list" do %>
  <!-- feedback items -->
<%% end %>
```

Filter form targets this frame:
```erb
<%%= form_with url: feedbacks_path, method: :get, data: { turbo_frame: "feedbacks_list" } do |f| %>
```

### Pagination with Turbo Frames
Next/Previous buttons target the feedbacks_list frame:
```erb
<%%= link_to "Next", feedbacks_path(page: @page + 1), data: { turbo_frame: "feedbacks_list" } %>
```

## Task 2: Turbo Streams for AI Chat

The chat panel should use Turbo Streams to append messages without page reload.

### Create chat Turbo Stream template
Create `app/views/chat/create.turbo_stream.erb`:
```erb
<%%= turbo_stream.append "chat_messages" do %>
  <div class="max-w-[85%] text-[13px] leading-relaxed px-3.5 py-2.5 rounded-xl rounded-br-sm bg-indigo-500 text-white self-end">
    <%%= @user_message.content %>
  </div>
<%% end %>

<%%= turbo_stream.append "chat_messages" do %>
  <div class="max-w-[85%] text-[13px] leading-relaxed px-3.5 py-2.5 rounded-xl rounded-bl-sm bg-gray-50 self-start">
    <%%= simple_format(@assistant_message.content) %>
    <%% if @assistant_message.source_feedbacks.any? %>
      <span class="text-[11px] text-indigo-500 mt-1 block">
        Based on <%%= @assistant_message.source_feedbacks.count %> feedbacks
      </span>
    <%% end %>
  </div>
<%% end %>

<%%= turbo_stream.replace "chat_input" do %>
  <input
    id="chat_input"
    data-chat-panel-target="input"
    data-action="keydown.enter->chat-panel#send"
    type="text"
    class="flex-1 px-3 py-2 border border-gray-200 rounded-lg text-[13px] outline-none focus:border-indigo-400 focus:ring-2 focus:ring-indigo-500/10 transition-all placeholder-gray-300"
    placeholder="Ask about your feedback data..."
    value=""
  >
<%% end %>
```

### Update ChatController for Turbo Stream
```ruby
class ChatController < ApplicationController
  def create
    unless current_account.chat_enabled?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append("chat_messages",
            partial: "shared/chat_error",
            locals: { message: "AI Chat requires Growth or Scale plan." })
        end
        format.html { redirect_to dashboard_path, alert: "AI Chat requires Growth plan." }
      end
      return
    end

    @user_message = current_account.chat_messages.create!(
      role: :user,
      content: params[:message]
    )

    # Call RAG service
    result = Synthesis::RagChat.call(
      account: current_account,
      question: params[:message]
    )

    @assistant_message = current_account.chat_messages.create!(
      role: :assistant,
      content: result[:answer],
      metadata: { source_feedback_ids: result[:source_ids] }
    )

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to dashboard_path }
    end
  end
end
```

### Update chat panel partial for Turbo
The chat compose area should be a form that submits via Turbo:
```erb
<%%= form_with url: chat_path, method: :post, data: { turbo_stream: true } do |f| %>
  <div class="px-3.5 py-3 border-t border-gray-100 flex gap-2">
    <%%= f.text_field :message, id: "chat_input", ... %>
    <%%= f.submit "", class: "..." %>
  </div>
<%% end %>
```

## Task 3: Real-time Feedback Broadcast

When a new feedback arrives via webhook, broadcast it to the dashboard.

### Add ActionCable channel
Create `app/channels/feedback_channel.rb`:
```ruby
class FeedbackChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user.account
  end
end
```

### Broadcast from FeedbackIngestJob
After creating a feedback, broadcast:
```ruby
# In FeedbackIngestJob#perform, after feedback is created:
Turbo::StreamsChannel.broadcast_append_to(
  feedback.account,
  target: "recent_feedbacks",
  partial: "feedbacks/feedback_item",
  locals: { feedback: feedback }
)

# Also broadcast counter update
Turbo::StreamsChannel.broadcast_update_to(
  feedback.account,
  target: "feedbacks_count",
  html: feedback.account.feedbacks.count.to_s
)
```

### Create feedback item partial
Create `app/views/feedbacks/_feedback_item.html.erb` with the feed item design, used both in the dashboard and the broadcast.

### Subscribe to stream in dashboard
In dashboard view:
```erb
<%%= turbo_stream_from current_account %>
```

## Task 4: Turbo Frame for Source Connection Status

Each source card should be a Turbo Frame that can update independently:
```erb
<%% @sources.each do |source| %>
  <%%= turbo_frame_tag dom_id(source) do %>
    <!-- source card with status -->
  <%% end %>
<%% end %>
```

When a source connects via OAuth callback, update just that card.

## Task 5: Verify all Turbo interactions work
1. Change period selector → metrics update without full reload
2. Filter feedbacks → list updates in-frame
3. Send chat message → response appears via Turbo Stream
4. New webhook arrives → dashboard counter updates real-time
5. Connect a source → source card updates status
