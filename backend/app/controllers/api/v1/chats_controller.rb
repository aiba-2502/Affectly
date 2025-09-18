class Api::V1::ChatsController < ApplicationController
  before_action :authenticate_user!

  def create
    # セッションIDの生成または取得
    session_id = params[:session_id] || generate_session_id

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

    # ユーザーメッセージを保存（感情情報を含む）
    user_message = current_user.chat_messages.create!(
      content: chat_params[:content],
      role: "user",
      session_id: session_id,
      emotions: emotions,
      metadata: {
        timestamp: Time.current.to_i,
        device: request.user_agent
      }
    )

    # 過去のメッセージを取得
    past_messages = current_user.chat_messages
                                 .by_session(session_id)
                                 .order(created_at: :asc)
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
        all_session_messages = current_user.chat_messages
                                          .by_session(session_id)
                                          .order(created_at: :asc)

        prompt_service = DynamicPromptService.new(all_session_messages)
        dynamic_system_prompt = prompt_service.generate_system_prompt

        # temperatureも動的に調整（指定されていない場合）
        dynamic_temperature ||= prompt_service.recommended_temperature
      end

      # デフォルト値の設定
      dynamic_temperature ||= 0.7

      # メッセージを構築
      messages = ai_service.build_messages(
        past_messages[0...-1], # 最後のメッセージ（今回のユーザーメッセージ）を除く
        dynamic_system_prompt
      )

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

      # AIの応答を保存
      assistant_message = current_user.chat_messages.create!(
        content: ai_response["content"],
        role: "assistant",
        session_id: session_id,
        metadata: {
          model: ai_response["model"],
          provider: ai_response["provider"],
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

    messages = messages.order(created_at: :asc)
                       .page(params[:page])
                       .per(params[:per_page] || AppConstants::DEFAULT_PAGE_SIZE)

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
                           .select(:session_id, "MAX(created_at) as last_message_at", "COUNT(*) as message_count")
                           .group(:session_id)
                           .order("last_message_at DESC")

    render json: {
      sessions: sessions.map do |session|
        # セッション内のメッセージから感情を集約
        session_messages = current_user.chat_messages
                                      .by_session(session.session_id)
                                      .where(role: "user")

        # 全感情を集計
        all_emotions = session_messages.pluck(:emotions).flatten.compact
        emotion_summary = aggregate_emotions(all_emotions)

        {
          session_id: session.session_id,
          last_message_at: session.last_message_at,
          message_count: session.message_count,
          # 最初のメッセージを取得してプレビューとする
          preview: session_messages.first&.content&.truncate(100),
          # 感情情報を追加
          emotions: emotion_summary
        }
      end
    }
  end

  def destroy
    message = current_user.chat_messages.find(params[:id])
    message.destroy!

    render json: { message: "Message deleted successfully" }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Message not found" }, status: :not_found
  end

  def destroy_session
    session_id = params[:id]

    # セッションに属する全てのメッセージを削除
    deleted_count = current_user.chat_messages.where(session_id: session_id).destroy_all.count

    if deleted_count > 0
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

  def serialize_message(message)
    {
      id: message.id,
      content: message.content,
      role: message.role,
      session_id: message.session_id,
      metadata: message.metadata,
      emotions: message.emotions,
      created_at: message.created_at,
      updated_at: message.updated_at
    }
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
