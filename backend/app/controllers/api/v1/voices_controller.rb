require "net/http"
require "json"

module Api
  module V1
    class VoicesController < ApplicationController
      # 音声生成は認証不要（フロントエンドから直接呼び出し）
      # 必要に応じてbefore_actionで認証を追加可能

      def generate
        text = params[:text]

        if text.blank?
          render json: { error: "読み上げるテキストが指定されていません" }, status: :bad_request
          return
        end

        begin
          voice_data = generate_voice(text)
          render json: voice_data
        rescue => e
          Rails.logger.error "Voice generation failed: #{e.message}"
          render json: { error: "音声生成に失敗しました" }, status: :internal_server_error
        end
      end

      private

      def generate_voice(text)
        api_key = ENV["NIJIVOICE_API_KEY"]
        voice_id = ENV["NIJIVOICE_VOICE_ID"]

        if api_key.blank? || voice_id.blank?
          raise "にじボイスAPIの設定が不完全です"
        end

        uri = URI("https://api.nijivoice.com/api/platform/v1/voice-actors/#{voice_id}/generate-voice")

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.open_timeout = 10
        http.read_timeout = 30

        request = Net::HTTP::Post.new(uri)
        request["Content-Type"] = "application/json"
        request["x-api-key"] = api_key

        # にじボイスAPIの仕様に合わせたパラメータ
        speed = ENV["NIJIVOICE_SPEED"] || "1.0"
        request_body = {
          script: text,  # scriptフィールドが必須
          speed: speed,  # 文字列として送信
          format: "wav"
        }

        request.body = request_body.to_json

        response = http.request(request)

        case response.code.to_i
        when 200
          data = JSON.parse(response.body)

          # レスポンスから音声URLまたはBase64データを取得
          audio_url = data.dig("generatedVoice", "audioFileUrl") ||
                     data.dig("generatedVoice", "audioFileDownloadUrl")
          audio_data = data["audioData"]

          if audio_url
            { audioUrl: audio_url }
          elsif audio_data
            { audioData: audio_data }
          else
            raise "音声データが取得できませんでした"
          end
        when 401
          raise "APIキーが無効です"
        when 404
          raise "ボイスIDが見つかりません"
        when 429
          raise "API利用制限に達しました"
        when 400
          raise "リクエストパラメータが不正です"
        else
          raise "APIエラー: #{response.code}"
        end
      end
    end
  end
end
