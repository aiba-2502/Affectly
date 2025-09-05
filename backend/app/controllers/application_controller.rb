class ApplicationController < ActionController::API
  attr_reader :current_user
  
  def authorize_request
    header = request.headers['Authorization']
    header = header.split(' ').last if header
    
    # デバッグログは開発環境のみ
    Rails.logger.debug "Authorization attempt" if Rails.env.development?
    
    unless header
      render json: { errors: 'Authorization header missing' }, status: :unauthorized
      return
    end
    
    decoded = JsonWebToken.decode(header)
    
    unless decoded
      render json: { errors: 'Invalid token' }, status: :unauthorized
      return
    end
    
    @current_user = User.find(decoded[:user_id])
    # ユーザーIDのみログ出力（個人情報は出力しない）
    Rails.logger.info "User authenticated: ID #{@current_user.id}" if Rails.env.development?
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "User not found for authentication"
    render json: { errors: 'User not found' }, status: :unauthorized
  rescue JWT::DecodeError => e
    Rails.logger.error "JWT decode error occurred"
    render json: { errors: 'Invalid token format' }, status: :unauthorized
  rescue StandardError => e
    Rails.logger.error "Authorization failed: #{e.class.name}"
    render json: { errors: 'Authorization failed' }, status: :unauthorized
  end
end
