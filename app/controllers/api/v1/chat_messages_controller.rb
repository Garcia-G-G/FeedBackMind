class Api::V1::ChatMessagesController < Api::V1::BaseController
  def index
    messages = current_account.chat_messages
                              .includes(:user)
                              .chronological

    messages = messages.by_user(User.find(params[:user_id])) if params[:user_id].present?
    messages = paginate(messages)

    render json: {
      messages: messages.map { |m| message_json(m) }
    }
  end

  def create
    # Verify chat is enabled for this plan
    unless current_account.chat_enabled?
      return render json: {
        error: "RAG chat is not available on your current plan. Please upgrade to Growth or Scale.",
        code: "plan_limit"
      }, status: :forbidden
    end

    question = params.require(:message)
    user = current_account.users.find(params.require(:user_id))

    # Save the user's question
    user_message = ChatMessage.create!(
      account: current_account,
      user: user,
      role: :user,
      content: question
    )

    # Call RAG chat service
    result = Synthesis::RagChat.new.ask(
      account: current_account,
      question: question
    )

    # Save the assistant's response
    assistant_message = ChatMessage.create!(
      account: current_account,
      user: user,
      role: :assistant,
      content: result[:answer],
      source_feedback_ids: result[:source_feedback_ids]
    )

    render json: {
      question: message_json(user_message),
      answer: message_json(assistant_message),
      sources: result[:source_feedback_ids].length
    }, status: :created
  end

  private

  def message_json(message)
    {
      id: message.id,
      role: message.role,
      content: message.content,
      source_feedback_ids: message.source_feedback_ids,
      created_at: message.created_at
    }
  end
end
