class ChatController < ApplicationController
  def create
    message_text = params[:message]
    return render json: { error: 'Message is required' }, status: :bad_request if message_text.blank?

    user_message = ChatMessage.create!(
      account: current_account,
      role: :user,
      content: message_text
    )

    response_text = Synthesis::RagChat.call(
      account: current_account,
      message: message_text
    )

    assistant_message = ChatMessage.create!(
      account: current_account,
      role: :assistant,
      content: response_text
    )

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.append('messages', partial: 'chat_message', locals: { message: user_message }),
          turbo_stream.append('messages', partial: 'chat_message', locals: { message: assistant_message })
        ]
      end
    end
  end
end
