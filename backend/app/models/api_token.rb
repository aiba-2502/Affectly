# frozen_string_literal: true

require 'securerandom'
require 'digest'

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
  scope :active, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at <= ?', Time.current) }
  scope :expiring_soon, ->(days = 7) { 
    where('expires_at BETWEEN ? AND ?', Time.current, days.days.from_now) 
  }

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

  # Instance Methods
  attr_accessor :raw_token

  def active?
    expires_at.nil? || expires_at > Time.current
  end

  def expired?
    !active?
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
