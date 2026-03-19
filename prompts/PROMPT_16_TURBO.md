# PROMPT 16 — Turbo Frames + Streams for Real-Time UX

Make the app feel alive with Turbo for fast navigation and real-time updates.

## Task 1: Turbo Frames for Dashboard Period Switching

Wrap the dashboard metrics, timeline, and themes in turbo_frame_tag "dashboard_content". When the period selector changes (7d/30d/Quarter), update only that frame — no full page reload.

Update period_selector_controller.js to set frame.src with the new period param.

## Task 2: Turbo Frames for Feedbacks Filtering

Wrap the feedbacks list in turbo_frame_tag "feedbacks_list". The filter form should target this frame with data: { turbo_frame: "feedbacks_list" }. Pagination links also target the same frame.

## Task 3: Turbo Streams for AI Chat

Create app/views/chat/create.turbo_stream.erb that:
- Appends the user's message bubble to #chat_messages
- Appends the AI's response bubble to #chat_messages
- Clears the input field

Update ChatController to respond_to turbo_stream format. The chat form should submit via Turbo (form_with url: chat_path).

## Task 4: Create feedback item partial

Create app/views/feedbacks/_feedback_item.html.erb — a reusable partial for a single feedback row (sentiment dot, text, tags, source, time). Used in dashboard, feedbacks index, and broadcasts.

## Task 5: ActionCable for Live Feedback Broadcast

When new feedback arrives via webhook (FeedbackIngestJob), broadcast to the dashboard:

Create FeedbackChannel (app/channels/feedback_channel.rb):
- stream_for current_user.account

In FeedbackIngestJob, after creating feedback:
- Turbo::StreamsChannel.broadcast_append_to(account, target: "recent_feedbacks", partial: "feedbacks/feedback_item", locals: { feedback: feedback })

In dashboard view, add: turbo_stream_from current_account

## Task 6: Verify
1. Period selector updates dashboard without full reload
2. Feedback filters update list in-frame
3. Chat messages appear via Turbo Stream (no reload)
4. New webhook → feedback appears on dashboard in real-time
