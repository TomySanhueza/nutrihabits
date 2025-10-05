class NutritionistAiChatsController < ApplicationController
  before_action :authenticate_nutritionist!
  before_action :set_chat, only: [:show, :destroy, :ask]

  def index
    @chats = current_nutritionist.nutritionist_ai_chats.order(updated_at: :desc)
  end

  def show
    @messages = @chat.nutritionist_ai_messages.order(created_at: :asc)
  end

  def create
    @chat = current_nutritionist.nutritionist_ai_chats.create!(
      context: { created_at: Time.current }
    )
    redirect_to nutritionist_ai_chat_path(@chat)
  end

  def destroy
    @chat.destroy
    redirect_to nutritionist_ai_chats_path, notice: 'Chat eliminado exitosamente.'
  end

  def ask
    message = params[:message]

    respond_to do |format|
      format.turbo_stream do
        # Streaming con Turbo Streams
        response = Turbo::StreamsChannel.broadcast_stream_to(
          @chat,
          target: "messages",
          action: "append"
        )

        copilot = NutritionistAICopilotService.new(@chat)

        # Crear mensaje del usuario primero
        user_message = @chat.nutritionist_ai_messages.create!(
          role: 'user',
          content: message
        )

        # Broadcast del mensaje del usuario
        Turbo::StreamsChannel.broadcast_append_to(
          @chat,
          target: "messages",
          partial: "nutritionist_ai_chats/message",
          locals: { message: user_message }
        )

        # Preparar contenedor para respuesta del asistente
        assistant_message = @chat.nutritionist_ai_messages.create!(
          role: 'assistant',
          content: ""
        )

        Turbo::StreamsChannel.broadcast_append_to(
          @chat,
          target: "messages",
          partial: "nutritionist_ai_chats/message",
          locals: { message: assistant_message, streaming: true }
        )

        # Streaming de la respuesta
        full_response = ""
        copilot.ask(message) do |chunk|
          full_response += chunk

          # Actualizar el mensaje con el contenido acumulado
          Turbo::StreamsChannel.broadcast_replace_to(
            @chat,
            target: "message_#{assistant_message.id}",
            partial: "nutritionist_ai_chats/message",
            locals: { message: assistant_message.tap { |m| m.content = full_response }, streaming: true }
          )
        end

        # Actualizar mensaje final
        assistant_message.update!(content: full_response)

        Turbo::StreamsChannel.broadcast_replace_to(
          @chat,
          target: "message_#{assistant_message.id}",
          partial: "nutritionist_ai_chats/message",
          locals: { message: assistant_message, streaming: false }
        )

        # Limpiar el input
        Turbo::StreamsChannel.broadcast_update_to(
          @chat,
          target: "message_input",
          html: ""
        )
      end
    end
  end

  private

  def set_chat
    @chat = current_nutritionist.nutritionist_ai_chats.find(params[:id])
  end
end
