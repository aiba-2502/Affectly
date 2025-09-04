class Api::V1::ChatsController < ApplicationController
  before_action :authorize_request
  
  def create
    # セッションIDの生成または取得
    session_id = params[:session_id] || generate_session_id
    
    # ユーザーメッセージを保存
    user_message = current_user.chat_messages.create!(
      content: chat_params[:content],
      role: 'user',
      session_id: session_id,
      metadata: {
        timestamp: Time.current.to_i,
        device: request.user_agent
      }
    )
    
    # 過去のメッセージを取得（最新10件）
    past_messages = current_user.chat_messages
                                 .by_session(session_id)
                                 .order(created_at: :asc)
                                 .last(10)
    
    # OpenAI APIを呼び出し
    begin
      # APIキーが指定されていない場合は環境変数から取得
      api_key = chat_params[:api_key].presence || ENV['OPENAI_API_KEY']
      openai_service = OpenaiService.new(api_key)
      
      # メッセージを構築
      messages = openai_service.build_messages(
        past_messages[0...-1], # 最後のメッセージ（今回のユーザーメッセージ）を除く
        chat_params[:system_prompt]
      )
      
      # 今回のユーザーメッセージを追加
      messages << { role: 'user', content: chat_params[:content] }
      
      # AIの応答を取得
      ai_response = openai_service.chat(
        messages,
        model: chat_params[:model],
        temperature: chat_params[:temperature]&.to_f,
        max_tokens: chat_params[:max_tokens]&.to_i
      )
      
      # AIの応答を保存
      assistant_message = current_user.chat_messages.create!(
        content: ai_response['content'],
        role: 'assistant',
        session_id: session_id,
        metadata: {
          model: chat_params[:model] || 'gpt-4o-mini',
          timestamp: Time.current.to_i
        }
      )
      
      render json: {
        session_id: session_id,
        user_message: serialize_message(user_message),
        assistant_message: serialize_message(assistant_message)
      }, status: :ok
      
    rescue StandardError => e
      Rails.logger.error "Chat Error: #{e.message}"
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
  
  def index
    session_id = params[:session_id]
    
    messages = if session_id.present?
                 current_user.chat_messages.by_session(session_id)
               else
                 current_user.chat_messages
               end
    
    messages = messages.order(created_at: :desc)
                       .page(params[:page])
                       .per(params[:per_page] || 20)
    
    render json: {
      messages: messages.map { |msg| serialize_message(msg) },
      total_count: messages.total_count,
      current_page: messages.current_page,
      total_pages: messages.total_pages
    }
  end
  
  def sessions
    # ユニークなセッションIDのリストを取得
    sessions = current_user.chat_messages
                           .select(:session_id, 'MAX(created_at) as last_message_at', 'COUNT(*) as message_count')
                           .group(:session_id)
                           .order('last_message_at DESC')
    
    render json: {
      sessions: sessions.map do |session|
        {
          session_id: session.session_id,
          last_message_at: session.last_message_at,
          message_count: session.message_count,
          # 最初のメッセージを取得してプレビューとする
          preview: current_user.chat_messages
                                .by_session(session.session_id)
                                .where(role: 'user')
                                .first&.content&.truncate(100)
        }
      end
    }
  end
  
  def destroy
    message = current_user.chat_messages.find(params[:id])
    message.destroy!
    
    render json: { message: 'Message deleted successfully' }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Message not found' }, status: :not_found
  end
  
  private
  
  def chat_params
    params.permit(:content, :session_id, :api_key, :system_prompt, :model, :temperature, :max_tokens)
  end
  
  def generate_session_id
    SecureRandom.uuid
  end
  
  def serialize_message(message)
    {
      id: message.id,
      content: message.content,
      role: message.role,
      session_id: message.session_id,
      metadata: message.metadata,
      created_at: message.created_at,
      updated_at: message.updated_at
    }
  end
end