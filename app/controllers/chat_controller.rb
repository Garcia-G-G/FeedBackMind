class ChatController < ApplicationController
  def create
    unless current_account.chat_enabled?
      return render json: { error: "Chat requires Growth or Scale plan." }, status: :forbidden
    end

    message_text = params[:message]
    return head :bad_request if message_text.blank?

    user_message = ChatMessage.create!(
      account: current_account,
      user: current_user,
      role: :user,
      content: message_text
    )

    result = Synthesis::RagChat.new.ask(
      account: current_account,
      question: message_text
    )

    assistant_message = ChatMessage.create!(
      account: current_account,
      user: current_user,
      role: :assistant,
      content: result[:answer],
      source_feedback_ids: result[:source_feedback_ids]
    )

    render json: {
      user_message: { id: user_message.id, content: user_message.content, role: "user" },
      assistant_message: { id: assistant_message.id, content: assistant_message.content, role: "assistant" }
    }
  end
end
