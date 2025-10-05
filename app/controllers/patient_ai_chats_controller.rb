class PatientAiChatsController < ApplicationController
  before_action :authenticate_patient!
  before_action :set_chat, only: [:show, :destroy, :ask]

  def index
    @chats = current_patient.patient_ai_chats.order(updated_at: :desc)
  end

  def show
    @messages = @chat.patient_ai_messages.order(created_at: :asc)
  end

  def create
    @chat = current_patient.patient_ai_chats.create!
    redirect_to patient_ai_chat_path(@chat)
  end

  def destroy
    @chat.destroy
    redirect_to patient_ai_chats_path, notice: "Chat eliminado correctamente"
  end

  def ask
    message = params[:message]

    respond_to do |format|
      format.turbo_stream do
        response.headers['Content-Type'] = 'text/vnd.turbo-stream.html; charset=utf-8'

        # Streaming response
        self.response_body = Enumerator.new do |yielder|
          # Broadcast mensaje del usuario
          yielder << turbo_stream.append(
            "messages",
            partial: "patient_ai_chats/message",
            locals: { message: @chat.patient_ai_messages.create!(role: 'user', content: message) }
          )

          # Preparar contenedor para respuesta del asistente
          assistant_message_id = "assistant-message-#{Time.current.to_i}"
          yielder << turbo_stream.append(
            "messages",
            "<div id='#{assistant_message_id}' class='message assistant-message'><div class='message-content'></div></div>"
          )

          # Enviar chunks del asistente
          copilot = PatientAICopilotService.new(@chat)
          copilot.ask(message) do |chunk|
            yielder << turbo_stream.append(
              "#{assistant_message_id} .message-content",
              chunk
            )
          end

          # Scroll automático al final
          yielder << turbo_stream.append(
            "messages",
            "<script>document.getElementById('messages').scrollTop = document.getElementById('messages').scrollHeight;</script>"
          )
        end
      end
    end
  end

  private

  def set_chat
    @chat = current_patient.patient_ai_chats.find(params[:id])
  end
end
