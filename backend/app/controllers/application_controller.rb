class ApplicationController < ActionController::API
  attr_reader :current_user
  
  def authorize_request
    header = request.headers['Authorization']
    header = header.split(' ').last if header
    
    Rails.logger.info "Authorization header: #{header}"
    
    unless header
      render json: { errors: 'Authorization header missing' }, status: :unauthorized
      return
    end
    
    decoded = JsonWebToken.decode(header)
    Rails.logger.info "Decoded token: #{decoded.inspect}"
    
    unless decoded
      render json: { errors: 'Invalid token' }, status: :unauthorized
      return
    end
    
    @current_user = User.find(decoded[:user_id])
    Rails.logger.info "Current user: #{@current_user.inspect}"
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "User not found: #{e.message}"
    render json: { errors: 'User not found' }, status: :unauthorized
  rescue JWT::DecodeError => e
    Rails.logger.error "JWT decode error: #{e.message}"
    render json: { errors: e.message }, status: :unauthorized
  rescue StandardError => e
    Rails.logger.error "Authorization error: #{e.message}"
    render json: { errors: 'Authorization failed' }, status: :unauthorized
  end
end
