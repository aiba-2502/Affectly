module Api
  module V1
    class AuthController < ApplicationController
      before_action :authenticate_user!, only: [ :me, :logout ]
      before_action :check_rate_limit, only: [ :login ]

      def signup
        user = User.new(user_params)

        if user.save
          tokens = ApiToken.generate_token_pair(user)
          render json: {
            access_token: tokens[:access_token].raw_token,
            refresh_token: tokens[:refresh_token].raw_token,
            user: user_response(user)
          }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def login
        user = User.find_by(email: params[:email])

        if user&.authenticate(params[:password])
          # 古いトークンをクリーンアップ
          ApiToken.cleanup_old_tokens(user.id)

          tokens = ApiToken.generate_token_pair(user)
          render json: {
            access_token: tokens[:access_token].raw_token,
            refresh_token: tokens[:refresh_token].raw_token,
            user: user_response(user)
          }, status: :ok
        else
          render json: { error: "Invalid email or password" }, status: :unauthorized
        end
      end

      def refresh
        refresh_token_value = params[:refresh_token]

        if refresh_token_value.blank?
          return render json: { error: "Refresh token required" }, status: :unauthorized
        end

        # トークンを検索（無効化されたものも含む）
        encrypted = ApiToken.encrypt_token(refresh_token_value)
        refresh_token = ApiToken.find_by(encrypted_token: encrypted)

        # トークンが存在しない、またはリフレッシュトークンでない場合
        if refresh_token.nil? || !refresh_token.refresh?
          return render json: { error: "Invalid or expired refresh token" }, status: :unauthorized
        end

        # 既に無効化されているトークンの再利用を検知
        if refresh_token.revoked_at.present?
          # セキュリティ：トークンチェーン全体を無効化
          if refresh_token.chat_chain_id.present?
            ApiToken.where(chat_chain_id: refresh_token.chat_chain_id)
                    .update_all(revoked_at: Time.current)
          end
          return render json: { error: "Token reuse detected" }, status: :unauthorized
        end

        # トークンの有効期限チェック
        if !refresh_token.token_valid?
          return render json: { error: "Invalid or expired refresh token" }, status: :unauthorized
        end

        user = refresh_token.user

        # 古いトークンを無効化
        refresh_token.update!(revoked_at: Time.current)

        # 新しいトークンペアを生成（同じチェーンIDを維持）
        new_tokens = ApiToken.generate_token_pair(user)

        # 新しいリフレッシュトークンに同じチェーンIDを設定
        if refresh_token.chat_chain_id.present?
          new_tokens[:refresh_token].update!(chat_chain_id: refresh_token.chat_chain_id)
        end

        render json: {
          access_token: new_tokens[:access_token].raw_token,
          refresh_token: new_tokens[:refresh_token].raw_token
        }, status: :ok
      end

      def logout
        # アクセストークンを取得
        token_value = extract_token_from_header

        if token_value.blank?
          return render json: { error: "Authorization header required" }, status: :unauthorized
        end

        access_token = ApiToken.find_by_token(token_value)

        if access_token.nil?
          return render json: { error: "Invalid or expired token" }, status: :unauthorized
        end

        # アクセストークンを無効化
        access_token.update!(revoked_at: Time.current)

        # 同じユーザーの関連するリフレッシュトークンも無効化
        if access_token.user_id.present?
          ApiToken.where(
            user_id: access_token.user_id,
            token_kind: "refresh",
            revoked_at: nil
          ).update_all(revoked_at: Time.current)
        end

        render json: { message: "Logged out successfully" }, status: :ok
      end

      def me
        if current_user
          render json: user_response(current_user), status: :ok
        else
          render json: { error: "Not authenticated" }, status: :unauthorized
        end
      end

      private

      def user_params
        params.permit(:email, :password, :name)
      end

      def user_response(user)
        {
          id: user.id,
          email: user.email,
          name: user.name
        }
      end

      # authenticate_user!とextract_token_from_headerはApplicationControllerに移動済み

      def check_rate_limit
        # レート制限チェック（メールが提供されている場合のみ）
        return unless params[:email].present?

        # IPアドレスベースまたはメールベースのレート制限を実装
        # ここではシンプルにメールベースで実装
        cache_key = "login_attempts:#{params[:email]}"

        # Railsキャッシュを使用してカウント（実際の実装では Redis等を使用）
        attempts = Rails.cache.read(cache_key) || 0

        if attempts >= 10
          render json: { error: "Too many requests. Please try again later." }, status: :too_many_requests
          false
        else
          Rails.cache.write(cache_key, attempts + 1, expires_in: 1.minute)
        end
      end
    end
  end
end
