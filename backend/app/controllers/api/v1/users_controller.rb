module Api
  module V1
    class UsersController < ApplicationController
      before_action :authenticate_user!

      def me
        render json: user_response(@current_user), status: :ok
      end

      def update
        # パスワード変更の場合、現在のパスワードを確認
        if params[:password].present?
          unless params[:current_password].present? && @current_user.authenticate(params[:current_password])
            render json: { error: '現在のパスワードが正しくありません' }, status: :unprocessable_entity
            return
          end
        end

        # ユーザー情報を更新
        if @current_user.update(user_update_params)
          render json: { 
            user: user_response(@current_user),
            message: 'プロフィールを更新しました'
          }, status: :ok
        else
          render json: { 
            error: '更新に失敗しました',
            errors: @current_user.errors.full_messages 
          }, status: :unprocessable_entity
        end
      end

      private

      def user_update_params
        permitted = [:name, :email]
        permitted << :password if params[:password].present?
        params.permit(*permitted)
      end

      def user_response(user)
        {
          id: user.id,
          email: user.email,
          name: user.name,
          created_at: user.created_at,
          updated_at: user.updated_at
        }
      end

      def authenticate_user!
        token = request.headers['Authorization']&.split(' ')&.last
        return render json: { error: 'Token not provided' }, status: :unauthorized unless token

        begin
          payload = JWT.decode(token, Rails.application.credentials.secret_key_base || 'development_secret', true, algorithm: 'HS256').first
          @current_user = User.find(payload['user_id'])
        rescue JWT::DecodeError, ActiveRecord::RecordNotFound
          render json: { error: 'Invalid token' }, status: :unauthorized
        end
      end
    end
  end
end