class JsonWebToken
  # 統一されたシークレットキーを使用
  SECRET_KEY = 'development_secret_key_12345678901234567890'

  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY)
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY)[0]
    HashWithIndifferentAccess.new(decoded)
  rescue JWT::ExpiredSignature => e
    Rails.logger.error "JWT expired: #{e.message}"
    nil
  rescue JWT::DecodeError => e
    Rails.logger.error "JWT decode error: #{e.message}"
    nil
  rescue StandardError => e
    Rails.logger.error "Unexpected error in JsonWebToken.decode: #{e.message}"
    nil
  end
end