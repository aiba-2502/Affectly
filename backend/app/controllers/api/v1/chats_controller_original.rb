class Api::V1::ChatsController < ApplicationController
  before_action :authenticate_user!

  def create
    # セッションIDの生成または取得
    session_id = params[:session_id] || generate_session_id

    # Chat record を確保 (ChatSessionServiceなしで直接実装)
    chat = Chat.find_by(title: "session:#{session_id}", user: current_user)
    chat ||= Chat.create!(
      user: current_user,
      title: "session:#{session_id}"
    )

    # 感情を抽出（AIサービスを渡す）
    provider = chat_params[:provider].presence || "openai"
    api_key = chat_params[:api_key].presence
    ai_service_for_emotion = AiServiceV2.new(provider: provider, api_key: api_key)
    emotion_service = EmotionExtractionService.new(ai_service: ai_service_for_emotion)

    # 感情抽出を試みる（エラーが発生しても続行）
    emotions = begin
      emotion_service.extract_emotions(chat_params[:content])
    rescue => e
      Rails.logger.error "Emotion extraction failed: #{e.message}"
      []
    end

    # Messagesテーブルに保存
    user_message = nil
    ActiveRecord::Base.transaction do
      # 感情データを処理
      emotion_score = emotions.any? ? emotions.map { |e| e[:intensity] || 0.5 }.sum / emotions.size : 0.0
      emotion_keywords = emotions.map { |e| e[:name].to_s }

      # Messageテーブルに保存
      user_message = Message.create!(
        chat: chat,
        sender: current_user,
        content: chat_params[:content],
        sender_kind: Message::SENDER_USER,
        emotion_score: emotion_score,
        emotion_keywords: emotion_keywords,
        llm_metadata: {
          timestamp: Time.current.to_i,
          device: request.user_agent
        },
        sent_at: Time.current
      )
    end

    # 過去のメッセージを取得（Messagesテーブルから）
    past_messages = Message.joins(:chat)
                          .where(chat: chat)
                          .order(sent_at: :asc)
                          .last(AppConstants::MAX_PAST_MESSAGES)

    # AI APIを呼び出し
    begin
      # プロバイダーを取得（デフォルトはOpenAI）
      provider = chat_params[:provider].presence || "openai"

      # APIキーが指定されていない場合は環境変数から取得
      api_key = chat_params[:api_key].presence

      # AIサービスを初期化（新しいバージョンを使用）
      ai_service = AiServiceV2.new(provider: provider, api_key: api_key)

      # 動的プロンプトとパラメータを生成（system_promptが指定されていない場合のみ）
      dynamic_system_prompt = chat_params[:system_prompt]
      dynamic_temperature = chat_params[:temperature]&.to_f

      if chat_params[:system_prompt].blank?
        # セッション全体のメッセージを取得（動的プロンプト生成用）
        all_session_messages = Message.joins(:chat)
                                     .where(chat: chat)
                                     .order(sent_at: :asc)

        # Messageオブジェクトをchat_messageライクなオブジェクトに変換
        chat_message_like = all_session_messages.map do |msg|
          OpenStruct.new(
            content: msg.content,
            role: msg.sender_id == current_user.id ? "user" : "assistant",
            emotions: msg.emotion_keywords&.map { |k| { name: k, intensity: msg.emotion_score } }
          )
        end

        prompt_service = DynamicPromptService.new(chat_message_like)
        dynamic_system_prompt = prompt_service.generate_system_prompt

        # temperatureも動的に調整（指定されていない場合）
        dynamic_temperature ||= prompt_service.recommended_temperature
      end

      # デフォルト値の設定
      dynamic_temperature ||= 0.7

      # メッセージを構築（Messageオブジェクトから）
      messages = past_messages[0...-1].map do |msg|
        {
          role: msg.sender_id == current_user.id ? "user" : "assistant",
          content: msg.content
        }
      end

      # システムプロンプトを追加
      if dynamic_system_prompt.present?
        messages.unshift({ role: "system", content: dynamic_system_prompt })
      end

      # 今回のユーザーメッセージを追加
      messages << { role: "user", content: chat_params[:content] }

      # AIの応答を取得
      Rails.logger.info "=== AI PARAMS DEBUG ==="
      Rails.logger.info "Received max_tokens: #{chat_params[:max_tokens]}"
      Rails.logger.info "Converted max_tokens to integer: #{chat_params[:max_tokens]&.to_i}"
      Rails.logger.info "Received temperature: #{chat_params[:temperature]}"
      Rails.logger.info "Converted temperature to float: #{chat_params[:temperature]&.to_f}"

      ai_response = ai_service.chat(
        messages,
        model: chat_params[:model],
        temperature: dynamic_temperature,
        max_tokens: chat_params[:max_tokens]&.to_i
      )

      # AIの応答を保存（Messagesテーブルに）
      assistant_message = nil
      ActiveRecord::Base.transaction do
        assistant_message = Message.create!(
          chat: chat,
          sender: current_user, # AIの応答も現在のユーザーのコンテキストで保存
          content: ai_response["content"],
          sender_kind: Message::SENDER_ASSISTANT,
          llm_metadata: {
            model: ai_response["model"],
            provider: ai_response["provider"],
            timestamp: Time.current.to_i,
            role: "assistant"
          },
          sent_at: Time.current
        )
      end

      # レスポンスをchat_message形式で返す（後方互換性）
      render json: {
        session_id: session_id,
        chat_id: chat.id,
        user_message: serialize_message_as_chat_message(user_message, session_id),
        assistant_message: serialize_message_as_chat_message(assistant_message, session_id)
      }, status: :ok

    rescue StandardError => e
      Rails.logger.error "Chat Error: #{e.message}"
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  def index
    session_id = params[:session_id]

    if session_id.present?
      # session_idからchatを特定
      chat = Chat.find_by(title: "session:#{session_id}", user: current_user)

      if chat
        messages = Message.where(chat: chat)
                         .order(sent_at: :asc)
                         .page(params[:page])
                         .per(params[:per_page] || AppConstants::DEFAULT_PAGE_SIZE)

        render json: {
          messages: messages.map { |msg| serialize_message_as_chat_message(msg, session_id) },
          total_count: messages.total_count,
          current_page: messages.current_page,
          total_pages: messages.total_pages
        }
      else
        render json: {
          messages: [],
          total_count: 0,
          current_page: 1,
          total_pages: 0
        }
      end
    else
      # 全てのチャットからメッセージを取得
      messages = Message.joins(:chat)
                       .where(chats: { user_id: current_user.id })
                       .order(sent_at: :asc)
                       .page(params[:page])
                       .per(params[:per_page] || AppConstants::DEFAULT_PAGE_SIZE)

      render json: {
        messages: messages.map { |msg|
          session_id = msg.chat.title.start_with?("session:") ? msg.chat.title.sub("session:", "") : "chat-#{msg.chat.id}"
          serialize_message_as_chat_message(msg, session_id)
        },
        total_count: messages.total_count,
        current_page: messages.current_page,
        total_pages: messages.total_pages
      }
    end
  end

  def sessions
    # Chatsテーブルからセッション情報を取得
    chats = current_user.chats
                        .joins(:messages)
                        .select("chats.*, MAX(messages.sent_at) as last_message_at, COUNT(messages.id) as message_count")
                        .group("chats.id")
                        .order("last_message_at DESC")

    render json: {
      sessions: chats.map do |chat|
        # session_idを復元
        session_id = chat.title.start_with?("session:") ? chat.title.sub("session:", "") : "chat-#{chat.id}"

        # チャット内のメッセージから感情を集約
        user_messages = Message.where(chat: chat, sender: current_user)

        # 感情情報を集計
        all_emotions = []
        user_messages.each do |msg|
          if msg.emotion_keywords.present?
            msg.emotion_keywords.each do |keyword|
              tag = get_emotion_tag(keyword)
              all_emotions << {
                name: keyword,
                label: tag ? tag.metadata["label_ja"] : keyword,
                intensity: msg.emotion_score || 0.5
              }
            end
          end
        end

        emotion_summary = aggregate_emotions(all_emotions)

        {
          session_id: session_id,
          chat_id: chat.id,
          last_message_at: chat.last_message_at,
          message_count: chat.message_count,
          preview: user_messages.first&.content&.truncate(100),
          emotions: emotion_summary
        }
      end
    }
  end

  def destroy
    message = Message.joins(:chat)
                    .where(chats: { user_id: current_user.id })
                    .find(params[:id])
    message.destroy!

    render json: { message: "Message deleted successfully" }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Message not found" }, status: :not_found
  end

  def destroy_session
    session_id = params[:id]

    # session_idからchatを特定
    chat = Chat.find_by(title: "session:#{session_id}", user: current_user)

    if chat
      # chatに属する全てのメッセージを削除
      deleted_count = Message.where(chat: chat).destroy_all.count

      # chat自体も削除
      chat.destroy

      render json: { message: "Session deleted successfully", deleted_count: deleted_count }, status: :ok
    else
      render json: { error: "Session not found" }, status: :not_found
    end
  rescue StandardError => e
    Rails.logger.error "Session deletion error: #{e.message}"
    render json: { error: "Failed to delete session" }, status: :internal_server_error
  end

  private

  def chat_params
    params.permit(:content, :session_id, :provider, :api_key, :system_prompt, :model, :temperature, :max_tokens)
  end

  def generate_session_id
    SecureRandom.uuid
  end

  def serialize_message_as_chat_message(message, session_id)
    {
      id: message.id,
      content: message.content,
      role: message.sender_kind == Message::SENDER_USER ? "user" : "assistant",
      session_id: session_id,
      metadata: message.llm_metadata,
      emotions: message.emotion_keywords&.map { |k|
        tag = get_emotion_tag(k)
        {
          name: k,
          label: tag ? tag.metadata["label_ja"] : k,
          intensity: message.emotion_score
        }
      },
      created_at: message.sent_at || message.created_at,
      updated_at: message.updated_at
    }
  end

  def get_emotion_tag(name)
    @emotion_tags_cache ||= load_emotion_tags_cache
    @emotion_tags_cache[name]
  end

  def load_emotion_tags_cache
    Rails.cache.fetch("emotion_tags_map", expires_in: 1.hour) do
      Tag.where(category: "emotion", is_active: true)
         .index_by(&:name)
    end
  end

  def aggregate_emotions(emotions)
    return [] if emotions.empty?

    # 感情の出現頻度と平均強度を計算
    emotion_map = {}

    emotions.each do |emotion|
      next unless emotion.is_a?(Hash)

      name = emotion["name"] || emotion[:name]
      intensity = (emotion["intensity"] || emotion[:intensity] || 0).to_f
      label = emotion["label"] || emotion[:label] || name

      if emotion_map[name]
        emotion_map[name][:count] += 1
        emotion_map[name][:total_intensity] += intensity
      else
        emotion_map[name] = {
          name: name,
          label: label,
          count: 1,
          total_intensity: intensity
        }
      end
    end

    # 上位3つの感情を返す（頻度と強度でソート）
    emotion_map.values
              .map do |e|
                {
                  name: e[:name],
                  label: e[:label],
                  intensity: (e[:total_intensity] / e[:count]).round(2),
                  frequency: e[:count]
                }
              end
              .sort_by { |e| [ -e[:frequency], -e[:intensity] ] }
              .first(3)
  end
end
