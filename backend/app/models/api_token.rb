# frozen_string_literal: true

require "securerandom"
require "digest"

class ApiToken < ApplicationRecord
  # Constants
  TOKEN_LENGTH = 32
  DEFAULT_EXPIRY_DAYS = 30

  # Associations
  belongs_to :user

  # Validations
  validates :encrypted_token, presence: true, uniqueness: true, length: { maximum: 191 }
  validates :user, presence: true

  # Callbacks
  before_validation :generate_and_encrypt_token, on: :create
  before_validation :set_expiry, on: :create

  # Scopes
  scope :active, -> { where(revoked_at: nil).where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }
  scope :expiring_soon, ->(days = 7) {
    where("expires_at BETWEEN ? AND ?", Time.current, days.days.from_now)
  }
  scope :access_tokens, -> { where(token_kind: "access") }
  scope :refresh_tokens, -> { where(token_kind: "refresh") }

  # Class Methods
  def self.find_by_token(raw_token)
    return nil if raw_token.blank?

    encrypted = encrypt_token(raw_token)
    active.find_by(encrypted_token: encrypted)
  end

  def self.authenticate(raw_token)
    token_record = find_by_token(raw_token)
    return nil unless token_record

    token_record.user if token_record.active?
  end

  def self.encrypt_token(raw_token)
    Digest::SHA256.hexdigest(raw_token)
  end

  # トークンペア生成（リフレッシュトークン対応）
  def self.generate_token_pair(user)
    chat_chain_id = SecureRandom.uuid

    # アクセストークン生成
    access_token = new(
      user: user,
      token_kind: "access",
      expires_at: 2.hours.from_now
    )
    # generate_and_encrypt_tokenコールバックでraw_tokenが設定される
    access_token.save!

    # raw_tokenを一時保存
    access_raw_token = access_token.raw_token

    # リフレッシュトークン生成
    refresh_token = new(
      user: user,
      token_kind: "refresh",
      expires_at: 7.days.from_now,
      chat_chain_id: chat_chain_id
    )
    refresh_token.save!

    # raw_tokenを一時保存
    refresh_raw_token = refresh_token.raw_token

    # raw_tokenが確実に設定されていることを確認
    raise "Access token raw_token is nil" if access_raw_token.nil?
    raise "Refresh token raw_token is nil" if refresh_raw_token.nil?

    # raw_tokenを再設定して返す（saveメソッドによってraw_tokenがクリアされる可能性があるため）
    access_token.raw_token = access_raw_token
    refresh_token.raw_token = refresh_raw_token

    { access_token: access_token, refresh_token: refresh_token }
  end

  # セキュアなトークン生成
  def self.generate_secure_token
    SecureRandom.urlsafe_base64(32)
  end

  # 古いトークンのクリーンアップ
  def self.cleanup_old_tokens(user_id, keep_count: 5)
    # ユーザーごとに最新のトークンチェーンのみ保持
    tokens = where(user_id: user_id, token_kind: "refresh")
             .active
             .order(created_at: :desc)
             .offset(keep_count)

    tokens.update_all(revoked_at: Time.current)
  end

  # Instance Methods
  attr_accessor :raw_token

  def active?
    revoked_at.nil? && (expires_at.nil? || expires_at > Time.current)
  end

  def expired?
    !active?
  end

  # トークン有効性チェック（リフレッシュトークン対応）
  def token_valid?
    revoked_at.nil? && expires_at.present? && expires_at > Time.current
  end

  # トークンチェーンの無効化
  def revoke_chain!
    if chat_chain_id.present?
      ApiToken.where(chat_chain_id: chat_chain_id)
              .update_all(revoked_at: Time.current)
    end
  end

  # トークンタイプ判定
  def refresh?
    token_kind == "refresh"
  end

  def access?
    token_kind == "access"
  end

  def expire!
    update!(expires_at: Time.current)
  end

  def refresh!(days = DEFAULT_EXPIRY_DAYS)
    update!(expires_at: days.days.from_now)
  end

  def days_until_expiry
    return nil unless expires_at
    ((expires_at - Time.current) / 1.day).ceil
  end

  private

  def generate_and_encrypt_token
    self.raw_token = SecureRandom.hex(TOKEN_LENGTH)
    self.encrypted_token = self.class.encrypt_token(raw_token)
  end

  def set_expiry
    self.expires_at ||= DEFAULT_EXPIRY_DAYS.days.from_now
  end
end
