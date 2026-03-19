class ChatController < ApplicationController
  def create
    unless current_account.chat_enabled?
      return respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.append("chat_messages", html: '<div class="text-center text-sm text-red-500 py-2">Chat requires Growth or Scale plan.</div>'.html_safe) }
        format.json { render json: { error: "Chat requires Growth or Scale plan." }, status: :forbidden }
      end
    end

    message_text = params[:message]
    return head :bad_request if message_text.blank?

    @user_message = ChatMessage.create!(
      account: current_account,
      user: current_user,
      role: :user,
      content: message_text
    )

    result = Synthesis::RagChat.new.ask(
      account: current_account,
      question: message_text
    )

    @assistant_message = ChatMessage.create!(
      account: current_account,
      user: current_user,
      role: :assistant,
      content: result[:answer],
      source_feedback_ids: result[:source_feedback_ids]
    )

    respond_to do |format|
      format.turbo_stream
      format.json do
        render json: {
          user_message: { id: @user_message.id, content: @user_message.content, role: "user" },
          assistant_message: { id: @assistant_message.id, content: @assistant_message.content, role: "assistant" }
        }
      end
    end
  end
end
