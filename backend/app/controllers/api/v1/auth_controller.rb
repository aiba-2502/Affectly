module Api
  module V1
    class AuthController < ApplicationController
      before_action :authenticate_user!, only: [:me, :logout]

      def signup
        user = User.new(user_params)
        
        if user.save
          token = generate_jwt_token(user)
          render json: { 
            token: token, 
            user: user_response(user) 
          }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def login
        user = User.find_by(email: params[:email])
        
        if user&.authenticate(params[:password])
          token = generate_jwt_token(user)
          render json: { 
            token: token, 
            user: user_response(user) 
          }, status: :ok
        else
          render json: { error: 'Invalid email or password' }, status: :unauthorized
        end
      end

      def logout
        render json: { message: 'Logged out successfully' }, status: :ok
      end

      def me
        if current_user
          render json: user_response(current_user), status: :ok
        else
          render json: { error: 'Not authenticated' }, status: :unauthorized
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

      def generate_jwt_token(user)
        payload = { user_id: user.id }
        JsonWebToken.encode(payload)
      end

      def authenticate_user!
        token = request.headers['Authorization']&.split(' ')&.last
        return render json: { error: 'Token not provided' }, status: :unauthorized unless token

        begin
          payload = JsonWebToken.decode(token)
          return render json: { error: 'Invalid token' }, status: :unauthorized unless payload
          
          @current_user = User.find(payload[:user_id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'Invalid token' }, status: :unauthorized
        end
      end

      def current_user
        @current_user
      end
    end
  end
end