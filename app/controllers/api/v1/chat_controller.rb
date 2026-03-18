module Api
  module V1
    class ChatController < BaseController
      before_action :ensure_chat_enabled

      # POST /api/v1/chat
      def create
        user = current_account.users.find(params[:user_id])

        # Save user message
        user_message = ChatMessage.create!(
          account: current_account,
          user: user,
          role: :user,
          content: params[:message]
        )

        # Get RAG-powered answer
        result = Synthesis::RagChat.new.ask(
          account: current_account,
          question: params[:message]
        )

        # Save assistant response
        assistant_message = ChatMessage.create!(
          account: current_account,
          user: user,
          role: :assistant,
          content: result[:answer],
          source_feedback_ids: result[:source_feedback_ids]
        )

        render json: {
          user_message: message_json(user_message),
          assistant_message: message_json(assistant_message)
        }, status: :created
      end

      # GET /api/v1/chat/history
      def history
        user = current_account.users.find(params[:user_id])
        messages = current_account.chat_messages.by_user(user).chronological

        render json: {
          messages: paginate(messages).map { |m| message_json(m) },
          meta: pagination_meta(messages)
        }
      end

      private

      def ensure_chat_enabled
        unless current_account.chat_enabled?
          render json: {
            error: "Chat is not available on your plan. Upgrade to Growth or Scale.",
            code: "plan_limit"
          }, status: :forbidden
        end
      end

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
  end
end
